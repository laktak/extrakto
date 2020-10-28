#!/bin/bash

CURRENT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_ACTIVE_PANE=$1
source "$CURRENT_DIR/helpers.sh"
EXTRAKTO="$CURRENT_DIR/../extrakto.py"
PLATFORM="$(uname)"

# options; note some of the values can be overwritten by capture()
GRAB_AREA=$(get_option "@extrakto_grab_area")
EXTRAKTO_OPT=$(get_option "@extrakto_default_opt")
CLIP_TOOL=$(get_option "@extrakto_clip_tool")
CLIP_TOOL_RUN=$(get_option "@extrakto_clip_tool_run")
FZF_TOOL=$(get_option "@extrakto_fzf_tool")
OPEN_TOOL=$(get_option "@extrakto_open_tool")
COPY_KEY=$(get_option "@extrakto_copy_key")
INSERT_KEY=$(get_option "@extrakto_insert_key")

CAPTURE_PANE_START=$(get_capture_pane_start "$GRAB_AREA")
ORIGINAL_GRAB_AREA=${GRAB_AREA} # keep this so we can cycle between alternatives on fzf

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


# note we use the superfluous 'local' keyword in front of 'captured' var;
# without it we get intermittent issues with extracto python script (when reading stdin);
# likely caused by some odd unicode-character encoding problem; debug by   echo "$captured" >> /tmp/capture
capture_panes() {
    local pane captured

    if [[ $GRAB_AREA =~ ^window\  ]]; then
        for pane in $(tmux list-panes -F "#{pane_active}:#{pane_id}"); do
            if [[ $pane =~ ^0: && ${pane:2} != ${LAST_ACTIVE_PANE} ]]; then
                local captured+="$(tmux capture-pane -pJS ${CAPTURE_PANE_START} -t ${pane:2})"
                captured+=$'\n'
            fi
        done
    fi

    local captured+="$(tmux capture-pane -pJS ${CAPTURE_PANE_START} -t !)"  # note the superfluous 'local' for some reason fixes the encoding problem

    echo "$captured"
}

capture() {
    local header_tmpl header extrakto_flags out res key text tmux_pane_num query

    header_tmpl="${COLORS[BOLD]}${INSERT_KEY}${COLORS[OFF]}=insert, ${COLORS[BOLD]}${COPY_KEY}${COLORS[OFF]}=copy"
    [[ -n "$OPEN_TOOL" ]] && header_tmpl+=", ${COLORS[BOLD]}ctrl-o${COLORS[OFF]}=open"
    header_tmpl+=", ${COLORS[BOLD]}ctrl-e${COLORS[OFF]}=edit, \
${COLORS[BOLD]}ctrl-f${COLORS[OFF]}=toggle filter [${COLORS[YELLOW]}${COLORS[BOLD]}{eo}${COLORS[OFF]}], \
${COLORS[BOLD]}ctrl-g${COLORS[OFF]}=grab area [${COLORS[YELLOW]}${COLORS[BOLD]}{ga}${COLORS[OFF]}]"

    while true; do
        header="$header_tmpl"
        header="${header/'{eo}'/$EXTRAKTO_OPT}"
        header="${header/'{ga}'/$GRAB_AREA}"

        case "$EXTRAKTO_OPT" in
            'path/url') extrakto_flags='pu' ;;
            'lines') extrakto_flags='l' ;;
            *) extrakto_flags='w' ;;
        esac

        # for troubleshooting add
        # tee /tmp/stageN | \
        # between the commands
        out="$(capture_panes \
            | $EXTRAKTO -r$extrakto_flags \
            | (read -r line && (
                echo "$line"
                cat
            ) || echo 'NO MATCH - use a different filter') \
            | $FZF_TOOL \
                --print-query \
                --query="$query" \
                --header="$header" \
                --expect=${INSERT_KEY},${COPY_KEY},ctrl-e,ctrl-f,ctrl-g,ctrl-o,ctrl-c,esc \
                --tiebreak=index)"
        res=$?
        mapfile -t out <<< "$out"
        query="${out[0]}"
        key="${out[1]}"
        text="${out[-1]}"

        if [[ $res -gt 0 && -z "$key" ]]; then
            echo "error: unable to extract - check/report errors above"
            echo "You can also set the fzf path in options (see readme)."
            read  # pause
            exit
        fi

        case "$key" in
            "${COPY_KEY}")
                tmux set-buffer -- "$text"
                if [[ "$CLIP_TOOL_RUN" == "fg" ]]; then
                    # run in foreground as OSC-52 copying won't work otherwise
                    tmux run-shell "tmux show-buffer|$CLIP_TOOL"
                else
                    # run in background as xclip won't work otherwise
                    tmux run-shell -b "tmux show-buffer|$CLIP_TOOL"
                fi

                return 0
                ;;

            "${INSERT_KEY}")
                tmux set-buffer -- "$text"
                tmux paste-buffer -t !
                return 0
                ;;

            ctrl-f)
                if [[ $EXTRAKTO_OPT == 'word' ]]; then
                    EXTRAKTO_OPT='path/url'
                elif [[ $EXTRAKTO_OPT == 'path/url' ]]; then
                    EXTRAKTO_OPT='lines'
                else
                    EXTRAKTO_OPT='word'
                fi
                ;;

            ctrl-g)
                # cycle between options like this:
                # recent -> full -> window recent -> window full -> custom (if any) -> recent ...
                tmux_pane_num=$(tmux list-panes | wc -l)
                if [[ $GRAB_AREA == "recent" ]]; then
                    if [[ $tmux_pane_num -eq 2 ]]; then
                        GRAB_AREA="full"
                    else
                        GRAB_AREA="window recent"
                    fi
                elif [[ $GRAB_AREA == "window recent" ]]; then
                    GRAB_AREA="full"
                elif [[ $GRAB_AREA == "full" ]]; then
                    if [[ $tmux_pane_num -eq 2 ]]; then
                        GRAB_AREA="recent"

                        if [[ ! "$ORIGINAL_GRAB_AREA" =~ ^(window )?(recent|full)$ ]]; then
                            GRAB_AREA="$ORIGINAL_GRAB_AREA"
                        fi
                    else
                        GRAB_AREA="window full"
                    fi
                elif [[ $GRAB_AREA == "window full" ]]; then
                    GRAB_AREA="recent"

                    if [[ ! "$ORIGINAL_GRAB_AREA" =~ ^(window )?(recent|full)$ ]]; then
                        GRAB_AREA="$ORIGINAL_GRAB_AREA"
                    fi
                else
                    GRAB_AREA="recent"
                fi

                CAPTURE_PANE_START=$(get_capture_pane_start "$GRAB_AREA")
                ;;

            ctrl-o)
                if [[ -n "$OPEN_TOOL" ]]; then
                    tmux run-shell -b "cd -- $PWD; $OPEN_TOOL $text"
                    return 0
                fi
                ;;

            ctrl-e)
                tmux send-keys -t ! "$_EDITOR -- $text" 'C-m'
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

if [[ "$CLIP_TOOL" == "auto" ]]; then
    case "$PLATFORM" in
        'Linux')
            if [[ $(cat /proc/sys/kernel/osrelease) =~ 'Microsoft' ]]; then
                CLIP_TOOL='clip.exe'
            else
                CLIP_TOOL='xclip -i -selection clipboard >/dev/null'
            fi
            ;;
        'Darwin') CLIP_TOOL='pbcopy' ;;
        *) ;;
    esac
fi

if [[ "$OPEN_TOOL" == "auto" ]]; then
    case "$PLATFORM" in
        'Linux') OPEN_TOOL='xdg-open >/dev/null' ;;
        'Darwin') OPEN_TOOL='open' ;;
        *) OPEN_TOOL='' ;;
    esac
fi

if [[ -z $EDITOR ]]; then
    _EDITOR="vi"  # fallback
else
    _EDITOR="$EDITOR"
fi

# check terminal size, zoom pane if too small
lines=$(tput lines)
if [[ $lines -lt 7 ]]; then
    tmux resize-pane -Z
fi

capture
