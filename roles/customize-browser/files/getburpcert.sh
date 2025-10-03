#!/usr/bin/env bash
set -u

launch_and_fetch_burp_cert() {
  local burp_jar java_bin log tmpcert pid wait_timeout port rc
  port=8080
  wait_timeout=60
  tmpcert="${1:-/tmp/cacert.der}"

  burp_jar=$(find / -type f -name 'burp*.jar' 2>/dev/null | tail -n1)
  if [ -z "$burp_jar" ]; then
    printf 'ERROR: burp jar not found\n' >&2
    return 1
  fi

  java_bin=$(command -v java || echo /usr/lib/jvm/java-21-openjdk-amd64/bin/java)
  if [ ! -x "$java_bin" ]; then
    printf 'ERROR: java binary not found or not executable: %s\n' "$java_bin" >&2
    return 2
  fi

  log="$(mktemp /tmp/burp-launch.XXXXXX.log)"

  _port_listening() {
    if command -v ss >/dev/null 2>&1; then
      ss -ltn "( sport = :${port} )" >/dev/null 2>&1
      return $?
    elif command -v nc >/dev/null 2>&1; then
      nc -z 127.0.0.1 "${port}" >/dev/null 2>&1
      return $?
    elif command -v netstat >/dev/null 2>&1; then
      netstat -ltn 2>/dev/null | grep -q ":${port}\b"
      return $?
    else
      return 1
    fi
  }

  # If already listening, try to fetch directly
  if _port_listening; then
    printf 'Info: service already listening on port %s — trying to fetch cert to %s\n' "$port" "$tmpcert"
    if curl --fail -sS "http://127.0.0.1:${port}/cert" -o "$tmpcert"; then
      printf 'cert saved to %s\n' "$tmpcert"
      return 0
    else
      printf 'failed to download cert from existing service; see %s\n' "$log"
      return 3
    fi
  fi

  # Launch Burp and auto-accept license; give it a long stdin window
  (
    printf 'y\n'
    sleep 120
  ) | script -q -c "$java_bin -Djava.awt.headless=true -jar '$burp_jar'" /dev/null >"$log" 2>&1 &

  pid=$!
  printf 'Launched Burp (pid %s), log %s\n' "$pid" "$log"

  # Wait for the port to appear
  for i in $(seq 1 "$wait_timeout"); do
    if _port_listening; then
      printf 'Port %s is listening (after %s seconds)\n' "$port" "$i"
      break
    fi
    sleep 1
  done

  if ! _port_listening; then
    printf 'Timeout waiting for port %s; see %s\n' "$port" "$log" >&2
    return 4
  fi

  # fetch certificate
  if curl --fail -sS "http://127.0.0.1:${port}/cert" -o "$tmpcert"; then
    printf 'cert saved to %s\n' "$tmpcert"
    return 0
  else
    printf 'failed to download cert; see %s\n' "$log" >&2
    return 5
  fi
}

# run twice as you had before
launch_and_fetch_burp_cert || printf 'First attempt returned non-zero (see messages above)\n' >&2
sleep 15
launch_and_fetch_burp_cert || printf 'Second attempt returned non-zero (see messages above)\n' >&2

# final check: exit non-zero if cert not present
if [ -f /tmp/cacert.der ]; then
  printf 'Done: /tmp/cacert.der exists\n'
  exit 0
else
  printf 'ERROR: /tmp/cacert.der not found after attempts\n' >&2
  exit 10
fi
