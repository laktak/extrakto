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

capture_panes() {
    local pane captured

    if [[ $GRAB_AREA =~ ^window\  ]]; then
        for pane in $(tmux list-panes -F "#{pane_active}:#{pane_id}"); do
            if [[ $pane =~ ^0: && ${pane:2} != ${LAST_ACTIVE_PANE} ]]; then
                captured+=$(tmux capture-pane -pJS ${CAPTURE_PANE_START} -t ${pane:2})
                captured+=$'\n'
            fi
        done
    fi
    captured+=$(tmux capture-pane -pJS ${CAPTURE_PANE_START} -t !)

    echo "$captured"
}

capture() {
    local header extrakto_flags sel res key text tmux_pane_num

    header="${INSERT_KEY}=insert, ${COPY_KEY}=copy"
    if [ -n "$OPEN_TOOL" ]; then header="$header, ctrl-o=open"; fi
    header="$header, ctrl-e=edit"
    header="$header, ctrl-f=toggle filter [$EXTRAKTO_OPT], ctrl-g=grab area [$GRAB_AREA]"

    case "$EXTRAKTO_OPT" in
        'path/url') extrakto_flags='pu' ;;
        'lines') extrakto_flags='l' ;;
        *) extrakto_flags='w' ;;
    esac

    # for troubleshooting add
    # tee /tmp/stageN | \
    # between the commands
    sel="$(capture_panes \
        | $EXTRAKTO -r$extrakto_flags \
        | (read line && (
            echo "$line"
            cat
        ) || echo 'NO MATCH - use a different filter') \
        | $FZF_TOOL \
            --header="$header" \
            --expect=${INSERT_KEY},${COPY_KEY},ctrl-e,ctrl-f,ctrl-g,ctrl-o,ctrl-c,esc \
            --tiebreak=index)"

    res=$?
    key=$(head -1 <<< "$sel")
    text=$(tail -n +2 <<< "$sel")

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
            ;;

        "${INSERT_KEY}")
            tmux set-buffer -- "$text"
            tmux paste-buffer -t !
            ;;

        ctrl-f)
            if [[ $EXTRAKTO_OPT == 'word' ]]; then
                EXTRAKTO_OPT='path/url'
            elif [[ $EXTRAKTO_OPT == 'path/url' ]]; then
                EXTRAKTO_OPT='lines'
            else
                EXTRAKTO_OPT='word'
            fi
            capture
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

            capture
            ;;

        ctrl-o)
            if [[ -n "$OPEN_TOOL" ]]; then
                tmux run-shell -b "cd -- $PWD; $OPEN_TOOL $text"
            else
                capture
            fi
            ;;

        ctrl-e)
            tmux send-keys -t ! "$_EDITOR -- $text" 'C-m'
            ;;
    esac
}

# check terminal size, zoom pane if too small
lines=$(tput lines)
if [[ $lines -lt 7 ]]; then
    tmux resize-pane -Z
fi

capture
