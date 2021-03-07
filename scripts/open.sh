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
    IFS=, read popup_width popup_height <<< "$(get_option "@extrakto_popup_size")"
    IFS=, read popup_x popup_y <<< "$(get_option "@extrakto_popup_position")"
    rc=129
    while [ $rc -eq 129 ]; do
        tmux popup \
            -w ${popup_width} \
            -h ${popup_height:-$popup_width} \
            -x ${popup_x} \
            -y ${popup_y:-$popup_x} \
            -E "${extrakto} ${pane_id} popup"
        rc=$?
    done
    exit $rc
else
    split_size=$(get_option "@extrakto_split_size")
    tmux split-window -${split_direction} -l ${split_size} "tmux setw remain-on-exit off; ${extrakto} ${pane_id} split"
fi
