#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
extrakto="$CURRENT_DIR/../extrakto.py"

if [ -z "$1" ]; then
  echo "tmux-extrakto EXTRAKTO-OPT [CLIP-TOOL]"
  exit 1
fi

EXTRAKTO_OPT=$1
CLIP=$2
if [ -z "$CLIP" ]; then
  case "`uname`" in
    'Linux') CLIP='xclip -i -selection clipboard >/dev/null' ;;
    'Darwin') CLIP='pbcopy' ;;
    *) ;;
  esac
fi

function capture() {

  sel=$(tmux capture-pane -pJS -32768 -t ! | \
    $extrakto $EXTRAKTO_OPT | \
    fzf --header="tab=insert, enter=copy, toggle filter=ctrl-f ($EXTRAKTO_OPT)" --expect=tab,enter,ctrl-f)

  if [ $? -eq 0 ]; then

    key=$(head -1 <<< "$sel")
    text=$(tail -n +2 <<< "$sel")
    tmux set-buffer -- "$text"

    case $key in
      enter)
        # run in background as xclip won't work otherwise
        tmux run-shell -b "tmux show-buffer|$CLIP" ;;
      tab)
        tmux paste-buffer -t ! ;;
      ctrl-f)
        if [[ $EXTRAKTO_OPT == '-pur' ]]; then
          EXTRAKTO_OPT=-wr
        else
          EXTRAKTO_OPT=-pur
        fi
        capture
        ;;
    esac
  fi
}

capture
