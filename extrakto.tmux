#!/bin/sh

script_dir=$(dirname "$0")
script_dir=$(
	cd "$script_dir"
	pwd
)

. "$script_dir/scripts/helpers.sh"

extrakto_open="$script_dir/scripts/open.sh"
extrakto_key=$(get_option "@extrakto_key" "tab")

lowercase_key=$(echo $extrakto_key | tr '[:upper:]' '[:lower:]')

if [ "$lowercase_key" != "none" ]; then
	tmux bind-key "${extrakto_key}" run-shell "\"$extrakto_open\" \"#{pane_id}\""
fi
