#!/usr/bin/env bash

CURRENT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
trigger_pane=$1
mode=$2
source "$CURRENT_DIR/helpers.sh"
extrakto="$CURRENT_DIR/../extrakto.py"
platform="$(uname)"

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
extrakto_opt=$(get_option "@extrakto_default_opt")
clip_tool=$(get_option "@extrakto_clip_tool")
clip_tool_run=$(get_option "@extrakto_clip_tool_run")
fzf_tool=$(get_option "@extrakto_fzf_tool")
open_tool=$(get_option "@extrakto_open_tool")
copy_key=$(get_option "@extrakto_copy_key")
insert_key=$(get_option "@extrakto_insert_key")

capture_pane_start=$(get_capture_pane_start "$grab_area")
original_grab_area=${grab_area} # keep this so we can cycle between alternatives on fzf

if [[ "$clip_tool" == "auto" ]]; then
    case "$platform" in
        'Linux')
            if [[ $(cat /proc/sys/kernel/osrelease) =~ 'Microsoft' ]]; then
                clip_tool='clip.exe'
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
    if [[ $mode == popup ]]; then
        [[ $num_panes == 1 ]]
    else
        [[ $num_panes == 2 ]]
    fi
}

capture() {
    local header_tmpl header extrakto_flags out res key text query

    header_tmpl="${COLORS[BOLD]}${insert_key}${COLORS[OFF]}=insert, ${COLORS[BOLD]}${copy_key}${COLORS[OFF]}=copy"
    [[ -n "$open_tool" ]] && header_tmpl+=", ${COLORS[BOLD]}ctrl-o${COLORS[OFF]}=open"
    header_tmpl+=", ${COLORS[BOLD]}ctrl-e${COLORS[OFF]}=edit, "
    header_tmpl+="${COLORS[BOLD]}ctrl-f${COLORS[OFF]}=toggle filter [${COLORS[YELLOW]}${COLORS[BOLD]}:eo:${COLORS[OFF]}], "
    header_tmpl+="${COLORS[BOLD]}ctrl-g${COLORS[OFF]}=grab area [${COLORS[YELLOW]}${COLORS[BOLD]}:ga:${COLORS[OFF]}]"

    while true; do
        header="$header_tmpl"
        header="${header/:eo:/$extrakto_opt}"
        header="${header/:ga:/$grab_area}"

        case "$extrakto_opt" in
            'path/url') extrakto_flags='pu' ;;
            'lines') extrakto_flags='l' ;;
            *) extrakto_flags='w' ;;
        esac

        # for troubleshooting add
        # tee /tmp/stageN | \
        # between the commands
        out="$(capture_panes \
            | $extrakto -r$extrakto_flags \
            | (read -r line && (
                echo "$line"
                cat
            ) || echo 'NO MATCH - use a different filter') \
            | $fzf_tool \
                --print-query \
                --query="$query" \
                --header="$header" \
                --expect=${insert_key},${copy_key},ctrl-e,ctrl-f,ctrl-g,ctrl-o,ctrl-c,esc \
                --tiebreak=index)"
        res=$?
        mapfile -t out <<< "$out"
        query="${out[0]}"
        key="${out[1]}"
        text="${out[-1]}"

        if [[ $res -gt 0 && -z "$key" ]]; then
            echo "error: unable to extract - check/report errors above"
            echo "You can also set the fzf path in options (see readme)."
            read # pause
            exit
        fi

        case "$key" in
            "${copy_key}")
                tmux set-buffer -- "$text"
                if [[ "$clip_tool_run" == "fg" ]]; then
                    # run in foreground as OSC-52 copying won't work otherwise
                    tmux run-shell "tmux show-buffer|$clip_tool"
                else
                    # run in background as xclip won't work otherwise
                    tmux run-shell -b "tmux show-buffer|$clip_tool"
                fi

                return 0
                ;;

            "${insert_key}")
                tmux set-buffer -- "$text"
                tmux paste-buffer -t $trigger_pane
                return 0
                ;;

            ctrl-f)
                if [[ $extrakto_opt == 'word' ]]; then
                    extrakto_opt='path/url'
                elif [[ $extrakto_opt == 'path/url' ]]; then
                    extrakto_opt='lines'
                else
                    extrakto_opt='word'
                fi
                ;;

            ctrl-g)
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

            ctrl-o)
                if [[ -n "$open_tool" ]]; then
                    tmux run-shell -b "cd -- $PWD; $open_tool $text"
                    return 0
                fi
                ;;

            ctrl-e)
                tmux send-keys -t $trigger_pane "$editor -- $text" 'C-m'
                return 0
                ;;
            *)
                return 0
                ;;
        esac
    done
}

##############
# Entry
##############

if [[ $mode != popup ]]; then
    # check terminal size, zoom pane if too small
    lines=$(tput lines)
    if [[ $lines -lt 7 ]]; then
        tmux resize-pane -Z
    fi
fi

capture
