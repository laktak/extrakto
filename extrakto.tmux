#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bind-key X switch-client -Textract-mode
bind-key -Textract-mode p split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -p clip"
bind-key -Textract-mode P split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -p insert"
bind-key -Textract-mode u split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -u clip"
bind-key -Textract-mode U split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -u insert"
