#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"
tmux_extrakto="$CURRENT_DIR/scripts/tmux-extrakto.sh"

extrakto_key=$(get_tmux_option "@extrakto_key" "tab")
default_opt=$(get_tmux_option "@extrakto_default_opt" "wr")
split_direction=$(get_tmux_option "@extrakto_split_direction" "v")
split_size=$(get_tmux_option "@extrakto_split_size" "7")

tmux bind-key ${extrakto_key} split-window -${split_direction} -l ${split_size} "$tmux_extrakto -${default_opt}"
