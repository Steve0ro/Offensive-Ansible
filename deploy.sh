#!/usr/bin/env bash
set -euo pipefail

show_help() {
    cat <<EOF
Usage: $0 [-v|-q|-y|-h]

Options:
  -v    Run playbooks in verbose mode (adds -vvv)
  -q    Run playbooks in quiet mode (suppress output unless it fails)
  -y    Non-interactive: choose Normal mode without prompting
  -h    Show this help message

If no mode flag is provided the script will prompt to choose verbose / quiet / normal.
This script runs:
  1) ansible-playbook main.yml
  2) ansible-playbook playbooks/adaptix.yml   (only if #1 succeeds)
EOF
}

MODE="interactive"
NONINTERACTIVE=0

while getopts "vqyh" opt; do
  case "$opt" in
    v) MODE="verbose" ;;
    q) MODE="quiet" ;;
    y) MODE="normal"; NONINTERACTIVE=1 ;;
    h) show_help; exit 0 ;;
    *) show_help; exit 1 ;;
  esac
done
shift $((OPTIND-1))

sudo whoami >/dev/null 2>&1 || true

if ! command -v ansible-playbook >/dev/null 2>&1; then
    printf "[+] Installing Ansible\n"
    sudo apt-get update -y && sudo apt-get install -y ansible
    if [ $? -gt 0 ]; then
        printf "[!] Error occurred when attempting to install ansible package.\n"
        exit 1
    fi
fi

printf "[+] Downloading required Ansible collections\n"
if ! ansible-galaxy install -r requirements.yml; then
    printf "[!] Error occurred when attempting to install Ansible collections.\n"
    exit 1
fi

if [ "$MODE" = "interactive" ]; then
    printf "\nChoose run mode:\n"
    printf "  1) Verbose (more output) - adds -vvv\n"
    printf "  2) Quiet   (suppress output unless failure)\n"
    printf "  3) Normal  (default)\n"
    printf "Select [1-3] (default 3): "
    if [ "$NONINTERACTIVE" -eq 0 ] 2>/dev/null; then
      read -r choice || choice=""
    else
      choice=""
    fi
    case "$choice" in
      1) MODE="verbose" ;;
      2) MODE="quiet"   ;;
      3|"") MODE="normal" ;;
      *) MODE="normal" ;;
    esac
fi

VERBOSITY=""
if [ "$MODE" = "verbose" ]; then
    VERBOSITY="-vvv"
    printf "[+] Running playbooks in VERBOSE mode..\n"
elif [ "$MODE" = "quiet" ]; then
    printf "[+] Running playbooks in QUIET mode (output suppressed unless an error occurs)..\n"
else
    printf "[+] Running playbooks in NORMAL mode..\n"
fi

TMPLOGS=()
cleanup() {
    for f in "${TMPLOGS[@]:-}"; do
        [ -f "$f" ] || continue
        keep_var_name="KEEP_LOG_$(basename "$f" | tr ' .-/' '____')"
        if [ "${!keep_var_name:-0}" -eq 0 ]; then
            rm -f "$f" >/dev/null 2>&1 || true
        fi
    done
}
trap cleanup EXIT

run_playbook() {
    local playbook="$1"
    local name="${2:-$(basename "$playbook")}"

    local cmd="ansible-playbook \"$playbook\" -K $VERBOSITY"

    if [ "$MODE" = "quiet" ]; then
        local logfile
        logfile="$(mktemp "/tmp/deploy.${name}.XXXXXX.log")"
        TMPLOGS+=("$logfile")
        keep_var_name="KEEP_LOG_$(basename "$logfile" | tr ' .-/' '____')"
        declare "$keep_var_name=0"

        printf "[+] Running %s (quiet) - temporary log: %s\n" "$playbook" "$logfile"
        if bash -c "$cmd" >"$logfile" 2>&1; then
            printf "[+] %s finished successfully. (temporary log: %s removed)\n" "$playbook" "$logfile"
            rm -f "$logfile" || true
            declare "$keep_var_name=0"
            return 0
        else
            rc=$?
            declare "$keep_var_name=1"
            printf "\n[!] Error running %s (rc=%d). Showing tail of log %s:\n\n" "$playbook" "$rc" "$logfile"
            tail -n 300 "$logfile" || true
            printf "\nFull log retained at: %s\n" "$logfile"
            return $rc
        fi
    else
        if bash -c "$cmd"; then
            return 0
        else
            rc=$?
            printf "[!] Error running %s (rc=%d).\n" "$playbook" "$rc"
            return $rc
        fi
    fi
}

run_playbook "main.yml" "main"
rc=$?
if [ $rc -ne 0 ]; then
    printf "\n[!] Aborting: 'main.yml' failed with rc=%d\n" "$rc"
    exit $rc
fi

run_playbook "playbooks/adaptix.yml" "adaptix"
rc=$?
if [ $rc -ne 0 ]; then
    printf "\n[!] 'playbooks/adaptix.yml' failed with rc=%d\n" "$rc"
    exit $rc
fi

printf "\n[!] Finished all playbooks [!]\n\nDon't forget to sign out/sign in for Docker group membership to take effect.\n"
exit 0