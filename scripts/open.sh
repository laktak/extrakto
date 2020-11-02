#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$current_dir/helpers.sh"
extrakto="$current_dir/extrakto.sh"

pane_id=$1
split_direction=$(get_option "@extrakto_split_direction")
split_size=$(get_option "@extrakto_split_size")

if [[ $split_direction == a ]]; then
    if [[ -n $(tmux list-commands popup) ]]; then
        split_direction=p
    else
        split_direction=v
    fi
fi

if [[ $split_direction == p ]]; then
    tmux popup -w90% -h90% -KER "${extrakto} ${pane_id} popup"
else
    tmux split-window -${split_direction} -l ${split_size} "${extrakto} ${pane_id} split"
fi
