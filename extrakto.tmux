#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CLIP_KEY=$(tmux show-option -gqv "@extrakto_clip_key")
CLIP_OPT=$(tmux show-option -gqv "@extrakto_clip_opt")
INSERT_KEY=$(tmux show-option -gqv "@extrakto_insert_key")
INSERT_OPT=$(tmux show-option -gqv "@extrakto_insert_opt")

tmux bind-key ${CLIP_KEY:-e} split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -${CLIP_OPT:-wr} clip"
tmux bind-key ${INSERT_KEY:-tab} split-window -v -l 6 "$CURRENT_DIR/tmux-extrakto -${INSERT_OPT:-wr} insert"
