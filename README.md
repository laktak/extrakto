
# extrakto for tmux

![intro](https://github.com/laktak/extrakto/wiki/assets/intro1.gif)

**Output completions** - you can complete commands that require you to retype text that is already on the screen. This works everywhere, even in remote ssh sessions.

You can **fuzzy find your text** instead of selecting it by hand:

- press tmux `prefix + tab` to start extrakto
- fuzzy find the text/path/url/line
- press
  - `tab` to insert it to the current pane,
  - `enter` to copy it to the clipboard,
  - `ctrl-o` to open the path/url or
  - `ctrl-e` to edit with `$EDITOR`

Use it for paths, URLs, options from a man page, git hashes, docker container names, ...

## Installation

Requires [tmux](https://github.com/tmux/tmux/wiki), [fzf](https://github.com/junegunn/fzf) and Python 2/3. Supports Linux (xclip), macOS (pbcopy) and Bash on Windows clipboards.

### with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

Add the plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'laktak/extrakto'

Hit `prefix + I` to fetch the plugin and source it.

You should now have all `extrakto` key bindings defined.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/laktak/extrakto ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/extrakto.tmux

Reload the tmux environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now have all `extrakto` key bindings defined.

### Wiki

Add or look for special tips in our [wiki](https://github.com/laktak/extrakto/wiki).

### Options

To set any of these options write on your `~/.tmux.conf` file:

```
set -g <option> "<value>"
```

Where `<option>` and `<value>` are one of the specified here:

| Option                      | Default | Description |
| :---                        | :---:   | :--- |
| `@extrakto_key`             | `tab`   | The key binding to start. If you have any special requirements (like a custom key table) set this to '' and define a binding in your `.tmux.conf`. See `extrakto.tmux` for a sample. |
| `@extrakto_default_opt`     | `word`  | The default extract options (`word`, `lines` or `path/url`) |
| `@extrakto_split_direction` | `v`     | Whether the tmux split will be `v`ertical or `h`orizontal |
| `@extrakto_split_size`      | `7`     | The size of the tmux split |
| `@extrakto_grab_area`       | `full`  | Whether you want extrakto to grab data from the `recent` area, the `full` pane, all current window's `recent` areas or all current window's `full` panes. You can also set this option to any number you want (or number preceded by "window ", e.g. "window 500"), this allows you to grab a smaller amount of data from the pane(s) than the pane's limit. For instance, you may have a really big limit for tmux history but using the same limit may end up on having slow performance on Extrakto. |
| `@extrakto_clip_tool`       | `auto`  | Set this to whatever clipboard tool you would like extrakto to use to copy data into your clipboard. `auto` will try to choose the correct clipboard for your platform. |
| `@extrakto_clip_tool_run`   | `bg`    | Set this to `fg` to have your clipboard tool run in a foreground shell (enabling copying to clipboard using OSC52). |
| `@extrakto_fzf_tool`        | `fzf`   | Set this to path of fzf if it can't be found in your `PATH`. |
| `@extrakto_open_tool`       | `auto`  | Set this to path of your own tool or `auto` to use your platforms *open* implementation. |
| `@extrakto_copy_key`        | `enter` | Key to copy selection to clipboard. |
| `@extrakto_insert_key`      | `tab`   | Key to insert selection. |


Example:

```
set -g @extrakto_split_size "15"
set -g @extrakto_clip_tool "xsel --input --clipboard" # works better for nvim
set -g @extrakto_copy_key "tab"      # use tab to copy to clipboard
set -g @extrakto_insert_key "enter"  # use enter to insert selection
```

---

# CLI

You can also use extrakto as a standalone tool to extract tokens from text.

### Installation

For now simply clone the repository and link to the tool somewhere in your path:

```
git clone https://github.com/laktak/extrakto
cd extrakto
# assuming you `export PATH=$PATH:~/.local/bin` in your `.bashrc`:
ln -s $PWD/extrakto.py ~/.local/bin/extrakto
```

Requires Python 2/3.

### CLI Usage

```
usage: extrakto.py [-h] [-p] [-u] [-w] [-l] [-r] [-m MIN_LENGTH]

Extracts tokens from plaintext.

optional arguments:
  -h, --help            show this help message and exit
  -p, --paths           extract path tokens
  -u, --urls            extract url tokens
  -w, --words           extract word tokens
  -l, --lines           extract lines
  -r, --reverse         reverse output
  -m MIN_LENGTH, --min-length MIN_LENGTH
                        minimum token length
```

# Contributions

Special thanks go to @ivanalejandro0 and @maximbaz for their ideas and PRs!
