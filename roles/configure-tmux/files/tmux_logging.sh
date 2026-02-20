#!/usr/bin/env bash

LOG_DIR="$HOME/Logs"
SESSION="$(tmux display-message -p '#S')"
WINDOW="$(tmux display-message -p '#W')"
PANE="$(tmux display-message -p '#P')"

TIMESTAMP="$(date +%Y%m%dT%H%M%S)"
SESSION_DIR="$LOG_DIR/$SESSION"

mkdir -p "$SESSION_DIR"

LOG_FILE="$SESSION_DIR/${WINDOW}-${PANE}-${TIMESTAMP}.log"

tmux pipe-pane -o "stdbuf -oL cat \
| sed -r 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
| sed -r 's/\r//g' \
| awk 'NF { print strftime(\"%Y-%m-%d %H:%M:%S\"), \"|\", \$0; fflush(); }' \
>> \"$LOG_FILE\""


tmux display-message "Logging started: $LOG_FILE"