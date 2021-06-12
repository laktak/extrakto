#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"
extrakto_open="$CURRENT_DIR/scripts/open.sh"

extrakto_key=$(get_option "@extrakto_key")

if [[ $(echo $extrakto_key | tr [:upper:] [:lower:]) != none ]]; then
    tmux bind-key ${extrakto_key} run-shell "\"$extrakto_open\" \"#{pane_id}\""
fi
