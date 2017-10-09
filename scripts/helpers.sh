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
    split_direction=$(get_tmux_option "@extrakto_split_direction" "v")
    split_size=$(get_tmux_option "@extrakto_split_size" "7")
    grab_area=$(get_tmux_option "@extrakto_grab_area" "full")

    capture_start="-32768"

    if [ "$grab_area" == "recent" ]; then
        if [ "$split_direction" == "v" ]; then
            capture_start=-"$split_size"
        else
            # NOTE: having an horizontal split you may end up shifting some
            # visible lines upwards. I can't think of a reliable way of
            # calculating how many extra lines we should add to compensate that
            # movement. This will vary on how long are the lines you're seeing
            # by the time you open extrakto.
            # This value may need to be tweaked to be a better default.
            capture_start="0"
        fi
    fi

    echo $capture_start
}
