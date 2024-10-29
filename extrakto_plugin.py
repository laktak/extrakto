#!/usr/bin/env python3

import os
import platform
import re
import subprocess
import shutil
import sys
import traceback

from collections import OrderedDict
from extrakto import Extrakto, get_lines

PLATFORM = platform.system()
PRJ_URL = "https://github.com/laktak/extrakto"
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
HELP_PATH = os.path.join(SCRIPT_DIR, "HELP.md")

COLORS = {
    "RED": "\033[0;31m",
    "GREEN": "\033[0;32m",
    "BLUE": "\033[0;34m",
    "PURPLE": "\033[0;35m",
    "CYAN": "\033[0;36m",
    "WHITE": "\033[0;37m",
    "YELLOW": "\033[0;33m",
    "OFF": "\033[0m",
    "BOLD": "\033[1m",
}

DEFAULT_OPTIONS = {
    "@extrakto_clip_tool": "auto",
    "@extrakto_clip_tool_run": "bg",
    "@extrakto_copy_key": "enter",
    "@extrakto_edit_key": "ctrl-e",
    "@extrakto_filter_key": "ctrl-f",
    "@extrakto_filter_order": "word all line",
    "@extrakto_fzf_header": "i c o e f g h",
    "@extrakto_fzf_layout": "default",
    "@extrakto_fzf_tool": "fzf",
    "@extrakto_fzf_unset_default_opts": "true",
    "@extrakto_grab_area": "window full",
    "@extrakto_grab_key": "ctrl-g",
    "@extrakto_help_key": "ctrl-h",
    "@extrakto_history_limit": "2000",
    "@extrakto_insert_key": "tab",
    "@extrakto_open_key": "ctrl-o",
    "@extrakto_open_tool": "auto",
}


def get_option(option):
    option_value = (
        subprocess.check_output(["tmux", "show-option", "-gqv", option])
        .decode("utf-8")
        .strip()
    )
    if option_value:
        return option_value
    return DEFAULT_OPTIONS[option] if option in DEFAULT_OPTIONS else ""


def fzf_sel(command, data):
    p = subprocess.Popen(
        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=None
    )
    p.stdin.write(data.encode("utf-8") + b"\n")
    p.stdin.close()
    p.wait()
    res = p.stdout.read().decode("utf-8").split("\n")
    # omit last empty line
    return res[:-1]


def get_cap(mode, data):

    extrakto = None
    res = []
    run_list = []

    if mode == "all":
        extrakto = Extrakto(alt=True, prefix_name=True)
        run_list = extrakto.all()
    elif mode == "line":
        res += get_lines(data)
    else:
        extrakto = Extrakto()
        run_list = [mode]

    for name in run_list:
        res += extrakto[name].filter(data)

    if not res:
        res = ["NO MATCH - use a different filter"]

    res.reverse()
    return "\n".join([s for s in OrderedDict.fromkeys(res)])


class ExtraktoPlugin:

    def __init__(self, trigger_pane, launch_mode):
        self.trigger_pane = trigger_pane
        self.launch_mode = launch_mode
        # options; note some of the values can be overwritten by capture()
        self.clip_tool = get_option("@extrakto_clip_tool")
        self.clip_tool_run = get_option("@extrakto_clip_tool_run")
        self.copy_key = get_option("@extrakto_copy_key")
        self.edit_key = get_option("@extrakto_edit_key")
        self.editor = get_option("@extrakto_editor")
        self.filter_key = get_option("@extrakto_filter_key")
        self.fzf_header = get_option("@extrakto_fzf_header")
        self.fzf_layout = get_option("@extrakto_fzf_layout")
        self.fzf_tool = get_option("@extrakto_fzf_tool")
        self.grab_area = get_option("@extrakto_grab_area")
        self.grab_key = get_option("@extrakto_grab_key")
        self.help_key = get_option("@extrakto_help_key")
        self.insert_key = get_option("@extrakto_insert_key")
        self.open_key = get_option("@extrakto_open_key")
        self.open_tool = get_option("@extrakto_open_tool")

        self.original_grab_area = self.grab_area

        self.modes_list = get_option("@extrakto_filter_order").split(" ")
        self.next_mode = {}
        for i in range(len(self.modes_list)):
            if i == len(self.modes_list) - 1:
                self.next_mode[self.modes_list[i]] = self.modes_list[0]
            else:
                self.next_mode[self.modes_list[i]] = self.modes_list[i + 1]

        # avoid side effects from FZF_DEFAULT_OPTS
        if get_option("@extrakto_fzf_unset_default_opts") == "true":
            os.environ.pop("FZF_DEFAULT_OPTS", None)

        if self.clip_tool == "auto":
            if PLATFORM == "Linux":
                if re.search(
                    r"Microsoft|microsoft", open("/proc/sys/kernel/osrelease").read()
                ):
                    self.clip_tool = ExtraktoPlugin._get_wsl_clip_executable()
                elif os.environ.get("XDG_SESSION_TYPE", None) == "wayland":
                    self.clip_tool = "wl-copy"
                else:
                    self.clip_tool = "xclip -i -selection clipboard >/dev/null"
            elif PLATFORM == "Darwin":
                self.clip_tool = "pbcopy"

        if self.open_tool == "auto":
            if PLATFORM == "Linux":
                self.open_tool = "xdg-open >/dev/null"
            elif PLATFORM == "Darwin":
                self.open_tool = "open"

        if not self.editor:
            self.editor = os.environ.get("EDITOR", "vi")

        if launch_mode != "popup":
            # check terminal size, zoom pane if too small
            lines = int(subprocess.check_output("tput lines", shell=True))
            if lines < 7:
                subprocess.run("tmux resize-pane -Z", shell=True)

    def copy(self, text):
        if self.clip_tool_run == "fg":
            # run in foreground as OSC-52 copying won't work otherwise
            subprocess.run(["tmux", "set-buffer", "--", text], check=True)
            subprocess.run(
                ["tmux", "run-shell", f"tmux show-buffer|{self.clip_tool}"], check=True
            )
        elif self.clip_tool_run == "tmux_osc52":
            # use native tmux 3.2 OSC 52 functionality
            subprocess.run(["tmux", "set-buffer", "-w", "--", text], check=True)
        else:
            # run in background as xclip won't work otherwise
            subprocess.run(["tmux", "set-buffer", "--", text], check=True)
            subprocess.run(
                ["tmux", "run-shell", "-b", f"tmux show-buffer|{self.clip_tool}"],
                check=True,
            )

    def open(self, path):
        if self.open_tool:
            subprocess.run(
                ["tmux", "run-shell", "-b", f"cd -- $PWD; {self.open_tool} {path}"],
                check=True,
            )

    # this returns the start point parameter for `tmux capture-pane`.
    def get_capture_pane_start(self):
        if self.grab_area == "recent" or self.grab_area == "window recent":
            capture_start = "-10"
        elif self.grab_area == "full" or self.grab_area == "window full":
            history_limit = get_option("@extrakto_history_limit")
            capture_start = f"-{history_limit}"
        elif self.grab_area.startswith("window "):
            capture_start = f"-{self.grab_area[7:]}"
        else:
            capture_start = f"-{self.grab_area}"
        return capture_start

    def capture_panes(self):
        captured = ""
        capture_pane_start = self.get_capture_pane_start()

        if self.grab_area.startswith("window"):
            panes = subprocess.check_output(
                ["tmux", "list-panes", "-F", "#{pane_active}:#{pane_id}"],
                universal_newlines=True,
            ).split("\n")
            for pane in panes:
                # exclude the active (for split) and trigger panes
                # in popup mode the active and tigger panes are the same
                # todo: split by :
                if pane.startswith("0:") and pane[:2] != self.trigger_pane:
                    captured += (
                        subprocess.check_output(
                            [
                                "tmux",
                                "capture-pane",
                                "-pJS",
                                capture_pane_start,
                                "-t",
                                pane[2:],
                            ],
                            universal_newlines=True,
                        )
                        + "\n"
                    )

        captured += subprocess.check_output(
            [
                "tmux",
                "capture-pane",
                "-pJS",
                capture_pane_start,
                "-t",
                self.trigger_pane,
            ],
            universal_newlines=True,
            encoding="utf-8",
        )
        return captured

    def has_single_pane(self):
        num_panes = len(
            subprocess.check_output(
                ["tmux", "list-panes"], universal_newlines=True
            ).split("\n")
        )
        if self.launch_mode == "popup":
            return num_panes == 1
        else:
            return num_panes == 2

    def get_next_mode(self, next):
        if next == "initial":
            return (
                os.environ.get("extrakto_inital_mode", "").strip() or self.modes_list[0]
            )
        else:
            return self.next_mode[next]

    def capture(self):
        mode = self.get_next_mode("initial")
        header_tmpl = ""
        for o in self.fzf_header.split(" "):
            if header_tmpl:
                header_tmpl += ", "
            if o == "i":
                header_tmpl += (
                    f"{COLORS['BOLD']}{self.insert_key}{COLORS['OFF']}=insert"
                )
            elif o == "c":
                header_tmpl += f"{COLORS['BOLD']}{self.copy_key}{COLORS['OFF']}=copy"
            elif o == "o":
                if self.open_tool:
                    header_tmpl += (
                        f"{COLORS['BOLD']}{self.open_key}{COLORS['OFF']}=open"
                    )
            elif o == "e":
                header_tmpl += f"{COLORS['BOLD']}{self.edit_key}{COLORS['OFF']}=edit"
            elif o == "f":
                header_tmpl += f"{COLORS['BOLD']}{self.filter_key}{COLORS['OFF']}=filter [{COLORS['YELLOW']}{COLORS['BOLD']}:filter:{COLORS['OFF']}]"
            elif o == "g":
                header_tmpl += f"{COLORS['BOLD']}{self.grab_key}{COLORS['OFF']}=grab [{COLORS['YELLOW']}{COLORS['BOLD']}:ga:{COLORS['OFF']}]"
            elif o == "h":
                header_tmpl += f"{COLORS['BOLD']}{self.help_key}{COLORS['OFF']}=help"
            else:
                header_tmpl += "(config error)"

        query = ""
        while True:
            header = (
                header_tmpl.replace(":ga:", self.grab_area)
                .replace(":filter:", mode)
                .replace("ctrl-", "^")
            )

            # for troubleshooting add `tee /tmp/stageN | ` between the commands
            try:
                fzf_cmd = [
                    self.fzf_tool,
                    "--multi",
                    "--print-query",
                    f"--query={query}",
                    f"--header={header}",
                    f"--expect=ctrl-c,ctrl-g,esc",
                    f"--expect={self.insert_key},{self.copy_key},{self.filter_key},{self.edit_key},{self.open_key},{self.grab_key},{self.help_key}",
                    "--tiebreak=index",
                    f"--layout={self.fzf_layout}",
                    "--no-info",
                ]
                query, key, *selection = fzf_sel(
                    fzf_cmd,
                    get_cap(mode, self.capture_panes()),
                )
            except Exception as e:
                msg = (
                    str(fzf_cmd)
                    + "\n"
                    + traceback.format_exc()
                    + "\n"
                    + "error: unable to extract - check/report errors above"
                    + "\n"
                    + "If fzf is not found you need to set the fzf path in options (see readme)."
                )
                print(msg)
                confirm = input("Copy this message to the clipboard? [Y/n]")
                if confirm != "n":
                    self.copy(msg)
                sys.exit(0)

            text = ""
            if mode == "all":
                text = "\n".join(
                    next(iter(s.split(": ", 1)[1:2]), s) for s in selection
                )
            elif mode == "line":
                text = "\n".join(selection)
            else:
                text = " ".join(selection)

            if key == self.copy_key:
                self.copy(text)
                return 0
            elif key == self.insert_key:
                subprocess.run(["tmux", "set-buffer", "--", text], check=True)
                subprocess.run(
                    ["tmux", "paste-buffer", "-p", "-t", self.trigger_pane], check=True
                )
                return 0
            elif key == self.filter_key:
                mode = self.get_next_mode(mode)
            elif key == self.grab_key:
                # cycle between options like this:
                # recent -> full -> window recent -> window full -> custom (if any) -> recent ...
                if self.grab_area == "recent":
                    if self.has_single_pane():
                        self.grab_area = "full"
                    else:
                        self.grab_area = "window recent"
                elif self.grab_area == "window recent":
                    self.grab_area = "full"
                elif self.grab_area == "full":
                    if self.has_single_pane():
                        self.grab_area = "recent"
                        if not self.original_grab_area.startswith(
                            ("window ", "recent", "full")
                        ):
                            self.grab_area = self.original_grab_area
                    else:
                        self.grab_area = "window full"
                elif self.grab_area == "window full":
                    self.grab_area = "recent"
                    if not self.original_grab_area.startswith(
                        ("window ", "recent", "full")
                    ):
                        self.grab_area = self.original_grab_area
                else:
                    self.grab_area = "recent"
            elif key == self.open_key:
                self.open(text)
                return 0
            elif key == self.edit_key:
                subprocess.run(
                    [
                        "tmux",
                        "send-keys",
                        "-t",
                        self.trigger_pane,
                        f"{self.editor} -- {text}",
                        "C-m",
                    ],
                    check=True,
                )
                return 0
            elif key == self.help_key:
                try:
                    subprocess.run(["clear"], check=True)
                    subprocess.run(
                        ["less", "-+EF", HELP_PATH],
                        check=True,
                    )
                except Exception as _:
                    print(open(HELP_PATH).read())
                    print("error: unable show help with less")
                print("\nSince the help page is not 'extrakt'-able:")
                confirm = input(
                    "Do you wish to [o]pen or [c]opy the GitHub page or [a]bort? [ocA] "
                ).lower()
                if confirm == "o":
                    self.open(PRJ_URL)
                elif confirm == "c":
                    self.copy(PRJ_URL)
            else:
                return 0

    @staticmethod
    def _get_wsl_clip_executable():
        if shutil.which("clip.exe") is None:
            return "/mnt/c/Windows/System32/clip.exe"
        return "clip.exe"


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: extrakto-plugin.py trigger_pane launch_mode")
        sys.exit(1)
    else:
        ExtraktoPlugin(sys.argv[1], sys.argv[2]).capture()
