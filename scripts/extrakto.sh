#!/usr/bin/env bash
platform="$(uname)"

# first check the version of bash
if ! type mapfile &> /dev/null; then
    echo "error: extrakto needs a newer Bash"
    if [[ $platform == Darwin ]]; then
        echo "On macOS you need to install/update it with Homebrew."
    fi
    read # pause
    exit 1
fi

PRJ_URL=https://github.com/laktak/extrakto
current_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
trigger_pane=$1
launch_mode=$2
source "$current_dir/helpers.sh"
extrakto="$current_dir/../extrakto.py"

declare -Ar COLORS=(
    [RED]=$'\033[0;31m'
    [GREEN]=$'\033[0;32m'
    [BLUE]=$'\033[0;34m'
    [PURPLE]=$'\033[0;35m'
    [CYAN]=$'\033[0;36m'
    [WHITE]=$'\033[0;37m'
    [YELLOW]=$'\033[0;33m'
    [OFF]=$'\033[0m'
    [BOLD]=$'\033[1m'
)

# options; note some of the values can be overwritten by capture()
grab_area=$(get_option "@extrakto_grab_area")
clip_tool=$(get_option "@extrakto_clip_tool")
clip_tool_run=$(get_option "@extrakto_clip_tool_run")
fzf_tool=$(get_option "@extrakto_fzf_tool")
open_tool=$(get_option "@extrakto_open_tool")
copy_key=$(get_option "@extrakto_copy_key")
insert_key=$(get_option "@extrakto_insert_key")
filter_key=$(get_option "@extrakto_filter_key")
open_key=$(get_option "@extrakto_open_key")
edit_key=$(get_option "@extrakto_edit_key")
grab_key=$(get_option "@extrakto_grab_key")
help_key=$(get_option "@extrakto_help_key")
fzf_layout=$(get_option "@extrakto_fzf_layout")

capture_pane_start=$(get_capture_pane_start "$grab_area")
original_grab_area=${grab_area} # keep this so we can cycle between alternatives on fzf

if [[ "$clip_tool" == "auto" ]]; then
    case "$platform" in
        'Linux')
            if [[ $(cat /proc/sys/kernel/osrelease) =~ Microsoft|microsoft ]]; then
                clip_tool='clip.exe'
            elif [[ $XDG_SESSION_TYPE == "wayland" ]]; then
                clip_tool='wl-copy'
            else
                clip_tool='xclip -i -selection clipboard >/dev/null'
            fi
            ;;
        'Darwin') clip_tool='pbcopy' ;;
        *) ;;
    esac
fi

if [[ "$open_tool" == "auto" ]]; then
    case "$platform" in
        'Linux') open_tool='xdg-open >/dev/null' ;;
        'Darwin') open_tool='open' ;;
        *) open_tool='' ;;
    esac
fi

if [[ -z $EDITOR ]]; then
    editor="vi" # fallback
else
    editor="$EDITOR"
fi

copy() {
    if [[ "$clip_tool_run" == "fg" ]]; then
        # run in foreground as OSC-52 copying won't work otherwise
        tmux set-buffer -- "$1"
        tmux run-shell "tmux show-buffer|$clip_tool"
    elif [[ "$clip_tool_run" == "tmux_osc52" ]]; then
        # use native tmux 3.2 OSC 52 functionality
        tmux set-buffer -w -- "$1"
    else
        # run in background as xclip won't work otherwise
        tmux set-buffer -- "$1"
        tmux run-shell -b "tmux show-buffer|$clip_tool"
    fi
}

open() {
    if [[ -n "$open_tool" ]]; then
        tmux run-shell -b "cd -- $PWD; $open_tool $1"
        return 0
    fi
}

capture_panes() {
    local pane captured
    captured=""

    if [[ $grab_area =~ ^window\  ]]; then
        for pane in $(tmux list-panes -F "#{pane_active}:#{pane_id}"); do
            # exclude the active (for split) and trigger panes
            # in popup mode the active and tigger panes are the same
            if [[ $pane =~ ^0: && ${pane:2} != "$trigger_pane" ]]; then
                captured+="$(tmux capture-pane -pJS ${capture_pane_start} -t ${pane:2})"
                captured+=$'\n'
            fi
        done
    fi

    captured+="$(tmux capture-pane -pJS ${capture_pane_start} -t $trigger_pane)"

    echo "$captured"
}

has_single_pane() {
    local num_panes
    num_panes=$(tmux list-panes | wc -l)
    if [[ $launch_mode == popup ]]; then
        [[ $num_panes == 1 ]]
    else
        [[ $num_panes == 2 ]]
    fi
}

show_fzf_error() {
    echo "error: unable to extract - check/report errors above"
    echo "You can also set the fzf path in options (see readme)."
    read # pause
}

capture() {
    local mode header_tmpl header out res key text query

    mode=$(get_next_mode "initial")

    header_tmpl="${COLORS[BOLD]}${insert_key}${COLORS[OFF]}=insert"
    header_tmpl+=", ${COLORS[BOLD]}${copy_key}${COLORS[OFF]}=copy"
    [[ -n "$open_tool" ]] && header_tmpl+=", ${COLORS[BOLD]}${open_key}${COLORS[OFF]}=open"
    header_tmpl+=", ${COLORS[BOLD]}${edit_key}${COLORS[OFF]}=edit"
    header_tmpl+=", ${COLORS[BOLD]}${filter_key}${COLORS[OFF]}=filter [${COLORS[YELLOW]}${COLORS[BOLD]}:filter:${COLORS[OFF]}]"
    header_tmpl+=", ${COLORS[BOLD]}${grab_key}${COLORS[OFF]}=grab area [${COLORS[YELLOW]}${COLORS[BOLD]}:ga:${COLORS[OFF]}]"
    header_tmpl+=", ${COLORS[BOLD]}${help_key}${COLORS[OFF]}=help"

    get_cap() {
        if [[ $mode == all ]]; then
            capture_panes | $extrakto --warn-empty --alt --all --name -r
        elif [[ $mode == line ]]; then
            capture_panes | $extrakto --warn-empty -rl
        else
            capture_panes | $extrakto --warn-empty -rw
        fi
    }

    while true; do
        header=$header_tmpl
        header=${header/:ga:/$grab_area}
        header=${header/:filter:/$mode}

        # for troubleshooting add
        # tee /tmp/stageN | \
        # between the commands
        out="$(get_cap \
            | $fzf_tool \
                --multi \
                --print-query \
                --query="$query" \
                --header="$header" \
                --expect=${insert_key},${copy_key},${filter_key},${edit_key},${open_key},${grab_key},${help_key},ctrl-c,esc \
                --tiebreak=index \
                --layout="$fzf_layout" \
                --no-info)"
        res=$?
        {
            read query
            read key
            mapfile -t selection
        } <<< "$out"

        if [[ $res -gt 0 && -z "$key" ]]; then
            show_fzf_error
            exit 1
        fi

        case "$mode" in
            all)
                text="${selection[@]#*: }"
                ;;
            line)
                IFS=$'\n' text="${selection[*]}"
                ;;
            *)
                text="${selection[@]}"
                ;;
        esac

        case "$key" in
            "${copy_key}")
                copy "$text"
                return 0
                ;;

            "${insert_key}")
                tmux set-buffer -- "$text"
                tmux paste-buffer -p -t $trigger_pane
                return 0
                ;;

            "${filter_key}")
                mode=$(get_next_mode $mode)
                ;;

            "${grab_key}")
                # cycle between options like this:
                # recent -> full -> window recent -> window full -> custom (if any) -> recent ...
                if [[ $grab_area == "recent" ]]; then
                    if has_single_pane; then
                        grab_area="full"
                    else
                        grab_area="window recent"
                    fi
                elif [[ $grab_area == "window recent" ]]; then
                    grab_area="full"
                elif [[ $grab_area == "full" ]]; then
                    if has_single_pane; then
                        grab_area="recent"

                        if [[ ! "$original_grab_area" =~ ^(window )?(recent|full)$ ]]; then
                            grab_area="$original_grab_area"
                        fi
                    else
                        grab_area="window full"
                    fi
                elif [[ $grab_area == "window full" ]]; then
                    grab_area="recent"

                    if [[ ! "$original_grab_area" =~ ^(window )?(recent|full)$ ]]; then
                        grab_area="$original_grab_area"
                    fi
                else
                    grab_area="recent"
                fi

                capture_pane_start=$(get_capture_pane_start "$grab_area")
                ;;

            "${open_key}")
                open "$text"
                return 0
                ;;

            "${edit_key}")
                tmux send-keys -t $trigger_pane "$editor -- $text" 'C-m'
                return 0
                ;;

            "${help_key}")
                clear
                less -+EF $(realpath "$current_dir/../HELP.md")

                echo -e "\nSince the help page is not 'extrakt'-able:"
                read -p "Do you wish to [o]pen or [c]opy the GitHub page or [a]bort? [ocA]" -d'' -s -n1 confirm
                if [[ $confirm == o ]]; then
                    open $PRJ_URL
                elif [[ $confirm == c ]]; then
                    copy $PRJ_URL
                fi
                ;;

            *)
                return 0
                ;;
        esac
    done
}

# Entry

if [[ $launch_mode != popup ]]; then
    # check terminal size, zoom pane if too small
    lines=$(tput lines)
    if [[ $lines -lt 7 ]]; then
        tmux resize-pane -Z
    fi
fi

capture
