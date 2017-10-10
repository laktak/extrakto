#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"
extrakto="$CURRENT_DIR/../extrakto.py"

# We are not passing this parameter. TODO: configure as option?
# CLIP=$2
CLIP=""
if [ -z "$CLIP" ]; then
  case "`uname`" in
    'Linux') CLIP='xclip -i -selection clipboard >/dev/null' ;;
    'Darwin') CLIP='pbcopy' ;;
    *) ;;
  esac
fi

grab_area=$(get_option "@extrakto_grab_area")
capture_pane_start=$(get_capture_pane_start)
EXTRAKTO_OPT=$(get_option "@extrakto_default_opt")

function capture() {

  sel=$(tmux capture-pane -pJS ${capture_pane_start} -t ! | \
    $extrakto -r$EXTRAKTO_OPT | \
    fzf \
      --header="tab=insert, enter=copy, ctrl-f=toggle filter [$EXTRAKTO_OPT], ctrl-l=grab area [$grab_area]" \
      --expect=tab,enter,ctrl-f,ctrl-l \
      --tiebreak=index)

  key=$(head -1 <<< "$sel")
  text=$(tail -n +2 <<< "$sel")

  case $key in
    enter)
      tmux set-buffer -- "$text"
      # run in background as xclip won't work otherwise
      tmux run-shell -b "tmux show-buffer|$CLIP" ;;
    tab)
      tmux set-buffer -- "$text"
      tmux paste-buffer -t ! ;;
    ctrl-f)
      if [[ $EXTRAKTO_OPT == 'pu' ]]; then
        EXTRAKTO_OPT=w
      else
        EXTRAKTO_OPT=pu
      fi
      capture
      ;;
    ctrl-l)
      if [[ $grab_area == 'full' ]]; then
        grab_area="recent"
      else
        grab_area="full"
      fi
      capture_pane_start=$(get_capture_pane_start "$grab_area")
      capture
      ;;
  esac
}

capture
