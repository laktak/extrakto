#!/bin/bash

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

get_option() {
    local option=$1

    case $option in
        "@extrakto_key")
            echo $(get_tmux_option $option "tab") ;;

        "@extrakto_default_opt")
            echo $(get_tmux_option $option "word") ;;

        "@extrakto_split_direction")
            echo $(get_tmux_option $option "v") ;;

        "@extrakto_split_size")
            echo $(get_tmux_option $option "7") ;;

        "@extrakto_grab_area")
            echo $(get_tmux_option $option "full") ;;

        "@extrakto_clip_tool")
            echo $(get_tmux_option $option "auto") ;;

        "@extrakto_fzf_tool")
            echo $(get_tmux_option $option "fzf") ;;

        "@extrakto_open_tool")
            echo $(get_tmux_option $option "auto") ;;
    esac
}

# This returns the start point parameter for `tmux capture-pane`.
# The result will depend on how the user has set the grab area and grab size.
get_capture_pane_start() {
    local grab_area=$1

    if [[ "$grab_area" == "recent" || "$grab_area" == "window recent" ]]; then
        local capture_start="-10"

    elif [[ "$grab_area" == "full" || "$grab_area" == "window full" ]]; then
        # use the history limit, this is all the data on the pane
        # if not set just go with tmux's default
        local history_limit=$(get_tmux_option "history-limit" "2000")
        local capture_start="-${history_limit}"

    elif [[ "$grab_area" =~ ^window\  ]]; then
        # use the user defined limit for how much to grab from every pane in the current window
        local capture_start="-${grab_area:7}"

    else
        # use the user defined limit for how much to grab from the current pane
        local capture_start="-${grab_area}"
    fi

    echo $capture_start
}
