# extrakto help

You can give feedback or star extrakto at https://github.com/laktak/extrakto

Extrakto uses fzf. You only need to type a few keys to find your selection with a fuzzy match.

- Press *ctrl-f* to change to the next filter mode (*filter_key*)
  - *word*, the default filter allows you to select words (default min length=5)
  - *all*, runs all(*) filters and allows you select quotes, url, paths, etc. \
    You can define your own filters as well as selecting which are included in \
    the all selection (see extrakto.conf).
  - *line*, select full lines

- Press *ctrl-g* to change the grab area (see *grab_key* and configuration)
  - *full*, everything from the current pane
  - *window full*, everything from all panes in this window
  - *recent*, everything visible with a few lines from the history (current pane)
  - *window recent*, everything visible with a few lines from the history (window)

- Press *esc* or *ctrl-c* to cancel

- Use *shift-tab* to select multiple entries.

Actions that use the current selection:

- Press *tab* to insert the selection into the active tmux pane (*insert_key*).

- Press *enter* to copy the selection to the clipboard (*copy_key*).

- Press *ctrl-o* to pass the selection to the *open* command of your OS (*open_key*). \
  For example if you select a URL this will open the browser.

- Press *ctrl-e* to open the selection in your $EDITOR (*edit_key*). \
  This only makes sense if you select a path and if you are currently in a shell. \
  extrakto will send the command to launch the editor to your active pane.

You can change most keys, define your own filters and change other configuration options. Please see the GitHub readme for instructions.
