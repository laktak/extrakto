
# extrakto

Extracts path and url tokens from plaintext.

Can be used with tmux and fzf as a replacement for tmux-copycat.

## Installation

For now simply clone the repository and link to the tool somewhere in your path:

```
git clone https://github.com/laktak/extrakto
cd extrakto
# assuming you `export PATH=$PATH:~/.local/bin` in your `.bashrc`:
ln -s $PWD/extrakto.py ~/.local/bin/extrakto
ln -s $PWD/tmux-extrakto ~/.local/bin/tmux-extrakto
```

Requires Python 3 and optionally [fzf](https://github.com/junegunn/fzf).

Supports Linux and macOS.

### tmux

To use this tool with tmux you would

- pass in the desired pane via stdin
- extract either paths or urls
- pass it along to fzf (or something similar)
- and finally use it to set a tmux buffer or the clipboard.

This sample (for tmux 2.4+) defines a `extract-mode` that you enter with `X` and then use `p` to extract paths or `u` for urls (piping to xclip). The uppercase variants will insert the selection in the current pane.

```
bind-key X switch-client -Textract-mode
bind-key -Textract-mode p send -X cancel \; split-window -v -l 6 "tmux-extrakto -p clip"
bind-key -Textract-mode P send -X cancel \; split-window -v -l 6 "tmux-extrakto -p insert"
bind-key -Textract-mode u send -X cancel \; split-window -v -l 6 "tmux-extrakto -u clip"
bind-key -Textract-mode U send -X cancel \; split-window -v -l 6 "tmux-extrakto -u insert"
```

## CLI Usage

```
Usage: extrakto OPTION
Extracts tokens from plaintext.

-p                         extract path tokens
-u                         extract url tokens
```

