#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"
tmux_extrakto="$CURRENT_DIR/scripts/tmux-extrakto.sh"


clip_key=$(get_tmux_option "@extrakto_clip_key" "e")
clip_opt=$(get_tmux_option "@extrakto_clip_opt" "wr")
insert_key=$(get_tmux_option "@extrakto_insert_key" "tab")
insert_opt=$(get_tmux_option "@extrakto_insert_opt" "wr")
split_direction=$(get_tmux_option "@extrakto_split_direction" "v")
split_size=$(get_tmux_option "@extrakto_split_size" "6")


tmux bind-key ${clip_key} split-window -${split_direction} -l ${split_size} "$tmux_extrakto -${clip_opt} clip"
tmux bind-key ${insert_key} split-window -${split_direction} -l ${split_size} "$tmux_extrakto -${insert_opt} insert"
