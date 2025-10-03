#!/usr/bin/env bash
# Original Author: Brian - https://www.hackernotebook.com/posts/automatic-tmux-logging/

tmux pipe-pane -o 'stdbuf -oL sed -r "s/\x1B\[[0-9;]*[mK]//g" | stdbuf -oL ts "%Y-%m-%dT%H:%M:%S%z: " >> $HOME/Logs/#S-#W-#I-#P.log' \; display-message 'Started logging to #S-#W-#I-#P.log'