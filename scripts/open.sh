#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$current_dir/helpers.sh"
extrakto="$current_dir/extrakto.sh"

pane_id=$1
split_direction=$(get_option "@extrakto_split_direction")

if [[ $split_direction == a ]]; then
    if [[ -n $(tmux list-commands popup) ]]; then
        split_direction=p
    else
        split_direction=v
    fi
fi

if [[ $split_direction == p ]]; then
    popup_size=$(get_option "@extrakto_popup_size")
    popup_position=$(get_option "@extrakto_popup_position")
    popup_width=$(echo $popup_size | awk -F ',' '{ print $1 }')
    popup_height=$(echo $popup_size | awk -F ',' '{ print $2 }')
    popup_x=$(echo $popup_position | awk -F ',' '{ print $1 }')
    popup_y=$(echo $popup_position | awk -F ',' '{ print $2 }')
    tmux popup -w ${popup_width} -h ${popup_height} -x ${popup_x} -y ${popup_y} \
        -KER "${extrakto} ${pane_id} popup"
else
    split_size=$(get_option "@extrakto_split_size")
    tmux split-window -${split_direction} -l ${split_size} "${extrakto} ${pane_id} split"
fi
