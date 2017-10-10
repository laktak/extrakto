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
            echo $(get_tmux_option $option "w") ;;

        "@extrakto_split_direction")
            echo $(get_tmux_option $option "v") ;;

        "@extrakto_split_size")
            echo $(get_tmux_option $option "7") ;;

        "@extrakto_grab_area")
            echo $(get_tmux_option $option "full") ;;

        "@extrakto_grab_size")
            echo $(get_tmux_option $option "") ;;
    esac
}

# This returns the start point parameter for `tmux capture-pane`.
# The result will depend on how the user has set the grab area and grab size.
#
# If you pass a parameter to this function, it will be used to overwrite the
# user's grab area configuration.
get_capture_pane_start() {
    local grab_area=$(get_option "@extrakto_grab_area")
    grab_area=${1:-$grab_area}  # overwrite with $1, if set.

    if [ "$grab_area" == "recent" ]; then
        # TODO: check that this is good enough for "recent"
        local capture_start="-10"

        echo $capture_start
        return
    fi

    local grab_size=$(get_tmux_option "@extrakto_grab_size")

    if [[ -n "$grab_size" ]]; then
        # use the user defined limit for how much to grab
        local capture_start="-${grab_size}"
    else
        # otherwise use the history limit, this is all the data on the pane
        # if not set just go with tmux's default
        local history_limit=$(get_tmux_option "history-limit" "2000")
        local capture_start="-${history_limit}"
    fi

    echo $capture_start
}