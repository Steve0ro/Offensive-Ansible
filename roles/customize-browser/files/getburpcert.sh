#!/bin/bash
# burp=$(find / -name burp*.jar 2>/dev/null | tail -1)
# /bin/bash -c "timeout 45 /usr/lib/jvm/java-21-openjdk-amd64/bin/java -Djava.awt.headless=true -jar $burp < <(echo y) &" 
# sleep 30
# curl http://localhost:8080/cert -o /tmp/cacert.der
# exit

BURP_JAR=$(find / -type f -name 'burp*.jar' 2>/dev/null | tail -n1)
JAVA_BIN=$(command -v java || echo /usr/lib/jvm/java-21-openjdk-amd64/bin/java)
LOG=/tmp/burp-launch.log

( printf 'y\n'; sleep 120 ) | script -q -c "$JAVA_BIN -Djava.awt.headless=true -jar '$BURP_JAR'" /dev/null >"$LOG" 2>&1 &

BURP_PID=$!
echo "Launched (pid $BURP_PID), log $LOG"
for i in $(seq 1 30); do
  if ss -ltn "( sport = :8080 )" >/dev/null 2>&1 || nc -z 127.0.0.1 8080 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl --fail -sS http://127.0.0.1:8080/cert -o /tmp/cacert.der && echo "cert saved to /tmp/cacert.der" || echo "failed to download cert; see $LOG"
