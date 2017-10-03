#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"
tmux_extrakto="$CURRENT_DIR/scripts/tmux-extrakto.sh"


default_clip_key="e"
clip_key=$(get_tmux_option "@extrakto_clip_key" "$default_clip_key")

default_clip_opt="wr"
clip_opt=$(get_tmux_option "@extrakto_clip_opt" "$default_clip_opt")

default_insert_key="tab"
insert_key=$(get_tmux_option "@extrakto_insert_key" "$default_insert_key")

default_insert_opt="wr"
insert_opt=$(get_tmux_option "@extrakto_insert_opt" "$default_insert_opt")

default_split_direction="v"
split_direction=$(get_tmux_option "@extrakto_split_direction" "$default_split_direction")

default_split_size=6
split_size=$(get_tmux_option "@extrakto_split_size" "$default_split_size")


tmux bind-key ${clip_key} split-window -${split_direction} -l ${split_size} "$tmux_extrakto -${clip_opt} clip"
tmux bind-key ${insert_key} split-window -${split_direction} -l ${split_size} "$tmux_extrakto -${insert_opt} insert"
