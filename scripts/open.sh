#!/bin/sh

script_dir=$(dirname "$0")
script_dir=$(
	cd "$script_dir"
	pwd
)
. "$script_dir/helpers.sh"
extrakto="$script_dir/../extrakto_plugin.py"

pane_id=$1
split_direction=$(get_option "@extrakto_split_direction" "a")

if [ "$split_direction" = "a" ]; then
	if [ -n "$(tmux list-commands popup 2>/dev/null)" ]; then
		split_direction="p"
	else
		split_direction="v"
	fi
fi

extrakto_inital_mode="$2"
if [ "$split_direction" = "p" ]; then
	popup_size=$(get_option "@extrakto_popup_size" "90%")
	popup_width=$(echo $popup_size | cut -d',' -f1)
	popup_height=$(echo $popup_size | cut -d',' -f2)

	popup_position=$(get_option "@extrakto_popup_position" "C")
	popup_x=$(echo $popup_position | cut -d',' -f1)
	popup_y=$(echo $popup_position | cut -d',' -f2)

	rc=129
	while [ $rc -eq 129 ]; do
		tmux popup \
			-w "${popup_width}" \
			-h "${popup_height:-${popup_width}}" \
			-x "${popup_x}" \
			-y "${popup_y:-$popup_x}" \
			-e extrakto_inital_mode="${extrakto_inital_mode}" \
			-E "${extrakto} ${pane_id} popup"
		rc=$?
	done
	exit $rc
else
	split_size=$(get_option "@extrakto_split_size" 7)
	tmux split-window \
		-${split_direction} \
		-e extrakto_inital_mode="${extrakto_inital_mode}" \
		-l ${split_size} "tmux setw remain-on-exit off; ${extrakto} ${pane_id} split"
fi
