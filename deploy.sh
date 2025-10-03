#!/bin/sh
set -eu

show_help() {
    cat <<EOF
Usage: $0 [-v|-q|-y|-h]

Options:
  -v    Run playbook in verbose mode (adds -vvv)
  -q    Run playbook in quiet mode (suppress output unless it fails)
  -y    Non-interactive: run in normal mode without prompting
  -h    Show this help message
If no mode flag is provided the script will prompt to choose verbose / quiet / normal.
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

if ! command -v ansible >/dev/null 2>&1; then
    printf "[+] Installing Ansible\n"
    sudo apt-get update -y && sudo apt-get install -y ansible
    if [ $? -gt 0 ]; then
        printf "[!] Error occurred when attempting to install ansible package.\n"
        exit 1
    fi
fi

printf "[+] Downloading required Ansible collections\n"
ansible-galaxy install -r requirements.yml
if [ $? -gt 0 ]; then
    printf "[!] Error occurred when attempting to install Ansible collections.\n"
    exit 1
fi

if [ "$MODE" = "interactive" ]; then
    printf "\nChoose run mode:\n"
    printf "  1) Verbose (more output) - adds -vvv\n"
    printf "  2) Quiet   (suppress output unless failure)\n"
    printf "  3) Normal  (default)\n"
    printf "Select [1-3] (default 3): "
    read -r choice
    case "$choice" in
      1) MODE="verbose" ;;
      2) MODE="quiet"   ;;
      3|"") MODE="normal" ;;
      *) MODE="normal" ;;
    esac
fi

ANSIBLE_PLAYBOOK_CMD="ansible-playbook main.yml -K"
if [ "$MODE" = "verbose" ]; then
    ANSIBLE_PLAYBOOK_CMD="$ANSIBLE_PLAYBOOK_CMD -vvv"
    printf "[+] Running playbooks in VERBOSE mode..\n"
elif [ "$MODE" = "quiet" ]; then
    printf "[+] Running playbooks in QUIET mode (output suppressed unless an error occurs)..\n"
else
    printf "[+] Running playbooks in NORMAL mode..\n"
fi

if [ "$MODE" = "quiet" ]; then
    LOGFILE="$(mktemp /tmp/deploy.XXXXXX.log)"
    printf "[+] Using temporary log: %s\n" "$LOGFILE"
    sh -c "$ANSIBLE_PLAYBOOK_CMD" >"$LOGFILE" 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
        printf "\n[!] Error occurred during playbook run (rc=%d). Showing log:\n\n" "$rc"
        sed -n '1,200p' "$LOGFILE" || true
        printf "\nFull log is at: %s\n" "$LOGFILE"
        exit $rc
    else
        printf "[+] Playbook finished successfully. (Log saved to %s)\n" "$LOGFILE"
        rm -f "$LOGFILE"
    fi
else
    sh -c "$ANSIBLE_PLAYBOOK_CMD"
    rc=$?
    if [ $rc -ne 0 ]; then
        printf "[!] Error occurred during playbook run (rc=%d).\n" "$rc"
        exit $rc
    fi
fi

printf "\n[!] Finished [!]\n\nDon't forget to sign out/sign in for Docker group membership to take effect.\n"
exit 0
