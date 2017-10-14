#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"
extrakto="$CURRENT_DIR/../extrakto.py"

# options
grab_area=$(get_option "@extrakto_grab_area")
extrakto_opt=$(get_option "@extrakto_default_opt")
fzf_tool=$(get_option "@extrakto_fzf_tool")
clip_tool=$(get_option "@extrakto_clip_tool")

capture_pane_start=$(get_capture_pane_start "$grab_area")
original_grab_area=${grab_area}  # keep this so we can cycle between alternatives on fzf

if [ -z "$clip_tool" ]; then
  case "`uname`" in
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


function capture() {

  sel=$(tmux capture-pane -pJS ${capture_pane_start} -t ! | \
    $extrakto -r$extrakto_opt | \
    $fzf_tool \
      --header="tab=insert, enter=copy, ctrl-f=toggle filter [$extrakto_opt], ctrl-l=grab area [$grab_area]" \
      --expect=tab,enter,ctrl-f,ctrl-l \
      --tiebreak=index)

  key=$(head -1 <<< "$sel")
  text=$(tail -n +2 <<< "$sel")

  case $key in

    enter)
      tmux set-buffer -- "$text"
      # run in background as xclip won't work otherwise
      tmux run-shell -b "tmux show-buffer|$clip_tool" ;;

    tab)
      tmux set-buffer -- "$text"
      tmux paste-buffer -t ! ;;

    ctrl-f)
      if [[ $extrakto_opt == 'pu' ]]; then
        extrakto_opt=w
      else
        extrakto_opt=pu
      fi
      capture
      ;;

    ctrl-l)
      # cycle between options like this: recent -> full -> custom (if any)-> recent ...
      if [[ $grab_area == "recent" ]]; then
          grab_area="full"
      elif [[ $grab_area == "full" ]]; then
          grab_area="recent"

          if [[ "$original_grab_area" != "recent" && "$original_grab_area" != "full" ]]; then
              grab_area="$original_grab_area"
          fi
      else
          grab_area="recent"
      fi

      capture_pane_start=$(get_capture_pane_start "$grab_area")

      capture
      ;;
  esac
}

capture
