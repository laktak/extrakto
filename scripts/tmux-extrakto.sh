#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
extrakto="$CURRENT_DIR/../extrakto.py"

if [ -z "$1" ]; then
  echo "tmux-extrakto EXTRAKTO-OPT [CLIP-TOOL]"
  exit 1
fi

EXTRAKTO_OPT=$1
capture_pane_start=$2

# CLIP=$2  # we are not passing this parameter
CLIP=""
if [ -z "$CLIP" ]; then
  case "`uname`" in
    'Linux') CLIP='xclip -i -selection clipboard >/dev/null' ;;
    'Darwin') CLIP='pbcopy' ;;
    *) ;;
  esac
fi

function capture() {

  sel=$(tmux capture-pane -pJS ${capture_pane_start} -t ! | \
    $extrakto -r$EXTRAKTO_OPT | \
    fzf \
      --header="tab=insert, enter=copy, ctrl-f=toggle filter [$EXTRAKTO_OPT]" \
      --expect=tab,enter,ctrl-f \
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
  esac
}

capture
