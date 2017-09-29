#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux bind-key e split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -wr clip"
tmux bind-key tab split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -wr insert"
