
# extrakto

![intro](https://github.com/laktak/extrakto/wiki/assets/intro1.gif)

## tmux plugin

When you work in tmux you often copy and paste text from the current buffer. With extrakto you can fuzzy find your text instead of selecting it by hand.

- press `prefix + tab` to start extrakto
- fuzzy find the required text/path/url
- press
  - `enter` to copy it to the clipboard,
  - `tab` to insert it to the current pane or
  - `ctrl-o` to open the path/url.
  - `ctrl-e` to open with `$EDITOR`

Requires Python 2/3 and [fzf](https://github.com/junegunn/fzf). Supports Linux (xclip), macOS (pbcopy) and Bash on Windows clipboards.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

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

### Options

To set any of these options write on your `~/.tmux.conf` file:

```
set -g <option> "<value>"
```

Where `<option>` and `<value>` are one of the specified here:

| Option                    | Default | Description |
| :---                      | :---:   | :--- |
| `@extrakto_key`             | `tab`   | The key binding to start. If you have any special requirements (like a custom key table) set this to '' and define a binding in your `.tmux.conf`. See `extrakto.tmux` for a sample. |
| `@extrakto_default_opt`     | `word`  | The default extract options (`word` or `path/url`) |
| `@extrakto_split_direction` | `v`     | Whether the tmux split will be `v`ertical or `h`orizontal |
| `@extrakto_split_size`      | `7`     | The size of the tmux split |
| `@extrakto_grab_area`       | `full`  | Whether you want extrakto to grab data from the `recent` area, or from `full` the pane. You can also set this option to any number you want, this allows you to grab a smaller amount of data from the pane than the pane's limit. For instance, you may have a really big limit for tmux history but using the same limit may end up on having slow performance on Extrakto. |
| `@extrakto_clip_tool`       | `auto`  | Set this to whatever clipboard tool you would like extrakto to use to copy data into your clipboard. `auto` will try to choose the correct clipboard for your platform. |
| `@extrakto_fzf_tool`        | `fzf`   | Set this to path of fzf if it can't be found in your `PATH`. |
| `@extrakto_open_tool`       | `auto`  | Set this to path of your own tool or `auto` to use your platforms *open* implementation. |


Example:

```
set -g @extrakto_split_size "15"
```

## CLI

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
usage: extrakto.py [-h] [-p] [-u] [-w] [-r] [-m MIN_LENGTH]

Extracts tokens from plaintext.

optional arguments:
  -h, --help            show this help message and exit
  -p, --paths           extract path tokens
  -u, --urls            extract url tokens
  -w, --words           extract word tokens
  -r, --reverse         reverse output
  -m MIN_LENGTH, --min-length MIN_LENGTH
                        minimum token length
```

# Contributions

Special thanks go to @ivanalejandro0 and @maximbaz for their ideas and PRs!
