#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
extrakto="$CURRENT_DIR/../extrakto.py"

if [ -z "$2" ]; then
  echo "tmux-extrakto EXTRAKTO-OPT {clip|insert} [CLIP-TOOL]"
  exit 1
fi

CLIP=$3
if [ -z "$CLIP" ]; then
  case "`uname`" in
    'Linux') CLIP='xclip -i -selection clipboard >/dev/null' ;;
    'Darwin') CLIP='pbcopy' ;;
    *) ;;
  esac
fi

tmux set-buffer -- `tmux capture-pane -pJS -32768 -t ! | \
  $extrakto $1 | \
  fzf --bind=tab:accept`

if [ $? -eq 0 ]; then
  case $2 in
    clip)
      # run in background as xclip won't work otherwise
      tmux run-shell -b "tmux show-buffer|$CLIP" ;;
    insert)
      tmux paste-buffer -t ! ;;
  esac
fi
