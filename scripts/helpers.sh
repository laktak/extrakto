get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value=$(tmux show-option -gqv "$option")

    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

get_capture_pane_start() {
    grab_area=$(get_tmux_option "@extrakto_grab_area" "full")

    history_limit=$(get_tmux_option 'history-limit' '2000')
    capture_start="-${history_limit}"

    if [ "$grab_area" == "recent" ]; then
        # TODO: check that this is good enough for "recent"
        capture_start="-10"
    fi

    echo $capture_start
}
