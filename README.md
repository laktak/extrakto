
# extrakto

Extracts path and url tokens from plaintext.

Can be used with tmux and fzf as a replacement for tmux-copycat.

## tmux

In tmux press `prefix + X` to enter extract mode. Now you can

- press `p` to extract paths
- press `u` to extract urls
- you can also use an uppercase version of the character to immediately pass in the selected value.

Extrakto will parse the current buffer and push everything into fzf. The item you select in fzf will then be copied or inserted.

Requires Python 3 and [fzf](https://github.com/junegunn/fzf). Supports Linux (xclip) and macOS (pbcopy) clipboards.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'laktak/extrakto'

Hit `prefix + I` to fetch the plugin and source it.

You should now have all `extrakto` key bindings defined.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/laktak/extrakto ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/extrakto.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now have all `extrakto` key bindings defined.

## CLI

### Installation

For now simply clone the repository and link to the tool somewhere in your path:

```
git clone https://github.com/laktak/extrakto
cd extrakto
# assuming you `export PATH=$PATH:~/.local/bin` in your `.bashrc`:
ln -s $PWD/extrakto.py ~/.local/bin/extrakto
```

Requires Python 3.

### CLI Usage

```
Usage: extrakto OPTION
Extracts tokens from plaintext.

-p                         extract path tokens
-u                         extract url tokens
```

