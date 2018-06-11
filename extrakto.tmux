#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"
tmux_extrakto="$CURRENT_DIR/scripts/tmux-extrakto.sh"

extrakto_key=$(get_option "@extrakto_key")
split_direction=$(get_option "@extrakto_split_direction")
split_size=$(get_option "@extrakto_split_size")

if [ -n "${extrakto_key}" ]; then
  tmux bind-key ${extrakto_key} run-shell "tmux split-window -c \"#{pane_current_path}\" -${split_direction} -l ${split_size} \"$tmux_extrakto #{pane_id}\""
fi
