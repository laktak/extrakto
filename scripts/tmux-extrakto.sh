#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LAST_ACTIVE_PANE=$1
source "$CURRENT_DIR/helpers.sh"
extrakto="$CURRENT_DIR/../extrakto.py"

# options
grab_area=$(get_option "@extrakto_grab_area")
extrakto_opt=$(get_option "@extrakto_default_opt")
clip_tool=$(get_option "@extrakto_clip_tool")
fzf_tool=$(get_option "@extrakto_fzf_tool")
open_tool=$(get_option "@extrakto_open_tool")

capture_pane_start=$(get_capture_pane_start "$grab_area")
original_grab_area=${grab_area}  # keep this so we can cycle between alternatives on fzf
os="$(uname)"

if [[ "$clip_tool" == "auto" ]]; then
  case "$os" in
    'Linux')
      if [[ "$(cat /proc/sys/kernel/osrelease)" =~ 'Microsoft' ]]; then
        clip_tool='clip.exe'
      elif command -v xsel >/dev/null 2>&1; then
        clip_tool='xsel --input --clipboard'
      else
        clip_tool='xclip -i -selection clipboard >/dev/null'
      fi
      ;;
    'Darwin') clip_tool='pbcopy' ;;
    *) ;;
  esac
fi

if [[ "$open_tool" == "auto" ]]; then
  case "$os" in
    'Linux') open_tool='xdg-open >/dev/null' ;;
    'Darwin') open_tool='open' ;;
    *) open_tool='' ;;
  esac
fi

if [[ -z $EDITOR ]]; then
  # fallback
  editor="vi"
else
  editor="$EDITOR"
fi

capture_panes() {
  local pane captured

  if [[ $grab_area =~ ^window\  ]]; then
    for pane in $(tmux list-panes -F "#{pane_active}:#{pane_id}"); do
      if [[ $pane =~ ^0: && ${pane:2} != ${LAST_ACTIVE_PANE} ]]; then
        captured+=$(tmux capture-pane -pJS ${capture_pane_start} -t ${pane:2})
        captured+=$'\n'
      fi
    done
  fi
  captured+=$(tmux capture-pane -pJS ${capture_pane_start} -t !)

  echo "$captured"
}

capture() {
  local header sel key text extrakto_flags

  header="tab=insert, enter=copy"
  [[ -n "$open_tool" ]] && header+=", ctrl-o=open"
  header+=", ctrl-e=edit, ctrl-f=toggle filter [$extrakto_opt], ctrl-l=grab area [$grab_area]"

  case "$extrakto_opt" in
    'path/url') extrakto_flags='pu' ;;
    'lines') extrakto_flags='l' ;;
    *) extrakto_flags='w' ;;
  esac

  # for troubleshooting add
  # tee /tmp/stageN | \
  # between the commands
  sel=$(capture_panes | \
    $extrakto -r$extrakto_flags | \
    (read -r line && (echo "$line"; cat) || echo NO MATCH - use a different filter) | \
    $fzf_tool \
      --header="$header" \
      --expect=tab,enter,ctrl-e,ctrl-f,ctrl-l,ctrl-o,ctrl-c,esc \
      --tiebreak=index)

  if [[ $? -ne 0 ]]; then
    echo "error: unable to extract - check/report errors above"
    echo "You can also set the fzf path in options (see readme)."
    read
    exit
  fi

  key=$(head -1 <<< "$sel")
  text=$(tail -n +2 <<< "$sel")

  case "$key" in
    enter)
      tmux set-buffer -- "$text"
      # run in background as xclip won't work otherwise
      tmux run-shell -b "tmux show-buffer|$clip_tool"
      ;;

    tab)
      tmux set-buffer -- "$text"
      tmux paste-buffer -t !
      ;;

    ctrl-f)
      if [[ $extrakto_opt == 'word' ]]; then
        extrakto_opt='path/url'
      elif [[ $extrakto_opt == 'path/url' ]]; then
        extrakto_opt='lines'
      else
        extrakto_opt='word'
      fi
      capture
      ;;

    ctrl-l)
      # cycle between options like this:
      # recent -> full -> window recent -> window full -> custom (if any) -> recent ...
      if [[ $grab_area == "recent" ]]; then
          grab_area="window recent"
      elif [[ $grab_area == "window recent" ]]; then
          grab_area="full"
      elif [[ $grab_area == "full" ]]; then
          grab_area="window full"
      elif [[ $grab_area == "window full" ]]; then
          grab_area="recent"

          if [[ ! "$original_grab_area" =~ ^(window )?(recent|full)$ ]]; then
              grab_area="$original_grab_area"
          fi
      else
          grab_area="recent"
      fi

      capture_pane_start=$(get_capture_pane_start "$grab_area")

      capture
      ;;

    ctrl-o)
      if [[ -n "$open_tool" ]]; then
        tmux run-shell -b "cd $PWD; $open_tool $text"
      else
        capture
      fi
      ;;

    ctrl-e)
      tmux send-keys -t ! "$editor -- $text" 'C-m'
      ;;
  esac
}

# check terminal size, zoom pane if too small
lines=$(tput lines)
if [[ $lines -lt 7 ]]; then
  tmux resize-pane -Z
fi

capture
