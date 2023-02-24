#!/usr/bin/env python3

import os
import re
import sys

from argparse import ArgumentParser
from collections import OrderedDict
from configparser import ConfigParser

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

# "words" consist of anything but the following characters:
# [](){}=$
# unicode range 2500-27BF which includes:
# - Box Drawing
# - Block Elements
# - Geometric Shapes
# - Miscellaneous Symbols
# - Dingbats
# unicode range E000-F8FF (private use/Powerline)
# and whitespace ( \t\n\r)
RE_WORD = "[^][(){}=$\u2500-\u27BF\uE000-\uF8FF \\t\\n\\r]+"


class Extrakto:
    def __init__(self, *, min_length=5, alt=False, prefix_name=False):
        conf = ConfigParser(interpolation=None)
        default_conf = os.path.join(SCRIPT_DIR, "extrakto.conf")
        user_conf = os.path.join(
            os.path.expanduser("~/.config"), "extrakto/extrakto.conf"
        )

        conf.read([default_conf, user_conf])
        sections = conf.sections()
        if not "path" in sections or not "url" in sections:
            raise Exception("extrakto.conf incomplete")

        self.min_length = min_length
        self.alt = alt
        self.prefix_name = prefix_name

        self.in_all = []
        self.fdict = {}
        for name in sections:
            sect = conf[name]
            alt = []
            for i in range(2, 10):
                key = f"alt{i}"
                if key in sect:
                    alt.append(sect[key])

            if sect.getboolean("in_all", fallback=True):
                self.in_all.append(name)

            if sect.getboolean("enabled", fallback=True):
                self.fdict[name] = FilterDef(
                    self,
                    name,
                    regex=sect.get("regex"),
                    exclude=sect.get("exclude", ""),
                    lstrip=sect.get("lstrip", ""),
                    rstrip=sect.get("rstrip", ""),
                    alt=alt,
                )

    def __getitem__(self, key):
        return self.fdict[key]

    def all(self):
        return self.in_all

    def keys(self):
        return list(self.fdict.keys())


class FilterDef:
    def __init__(self, extrakto, name, *, regex, exclude, lstrip, rstrip, alt):
        self.extrakto = extrakto
        self.name = name
        self.regex = regex
        self.exclude = exclude
        self.lstrip = lstrip
        self.rstrip = rstrip
        self.alt = alt

    def filter(self, text):
        res = list()
        if self.extrakto.prefix_name:
            add = lambda name, value: res.append(f"{name}: {value}")
        else:
            add = lambda name, value: res.append(value)

        for m in re.finditer(self.regex, "\n" + text, flags=re.I):
            item = "".join(filter(None, m.groups()))

            # strip invalid characters (like punctuation or markdown syntax)
            if self.lstrip:
                item = item.lstrip(self.lstrip)
            if self.rstrip:
                item = item.rstrip(self.rstrip)

            if len(item) >= self.extrakto.min_length:
                if not self.exclude or not re.search(self.exclude, item, re.I):
                    if self.extrakto.alt:
                        for i, altre in enumerate(self.alt):
                            m = re.search(altre, item)
                            if m:
                                add(f"{self.name}{i+2}", m[1])
                    add(self.name, item)
        return res


def get_lines(text, *, min_length=5, prefix_name=False):
    lines = []

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if len(line) >= min_length:
            if prefix_name:
                lines.append("line: " + line)
            else:
                lines.append(line)

    return lines


def main(parser):
    args = parser.parse_args()

    run_list = []
    if args.paths:
        run_list.append("path")
    if args.quote:
        run_list.append("quote")
    if args.squote:
        run_list.append("s-quote")
    if args.urls:
        run_list.append("url")
    if args.words:
        run_list.append("word")
    run_list += args.add

    res = []
    # input from the terminal can cause UnicodeDecodeErrors in some instances, ignore for now
    text = sys.stdin.buffer.read().decode("utf-8", "ignore")

    extrakto = Extrakto(min_length=args.min_length, alt=args.alt, prefix_name=args.name)
    if args.all:
        run_list = extrakto.all()

    if args.lines:
        res += get_lines(text, min_length=args.min_length, prefix_name=args.name)

    for name in run_list:
        res += extrakto[name].filter(text)

    if res:
        if args.reverse:
            res.reverse()

        # remove duplicates and print
        for item in OrderedDict.fromkeys(res):
            print(item)

    elif args.warn_empty:
        print("NO MATCH - use a different filter")


if __name__ == "__main__":
    parser = ArgumentParser(description="Extracts tokens from plaintext.")

    parser.add_argument(
        "--name", action="store_true", help="prefix filter name in the output"
    )

    parser.add_argument(
        "-w",
        "--words",
        "--word",
        dest="words",
        action="store_true",
        help='extract "word" tokens',
    )

    parser.add_argument("-l", "--lines", action="store_true", help="extract lines")

    parser.add_argument(
        "--all",
        action="store_true",
        help="extract using all filters defined in extrakto.conf",
    )

    parser.add_argument(
        "-a", "--add", action="append", default=[], help="add custom filter"
    )

    parser.add_argument("-p", "--paths", action="store_true", help="short for -a=path")

    parser.add_argument("-u", "--urls", action="store_true", help="short for -a=url")

    parser.add_argument("-q", "--quote", action="store_true", help="short for -a=quote")

    parser.add_argument(
        "-s", "--squote", action="store_true", help="short for -a=s-quote"
    )

    parser.add_argument(
        "--alt",
        action="store_true",
        help="return alternate variants for each match (e.g. https://example.com and example.com)",
    )

    parser.add_argument("-r", "--reverse", action="store_true", help="reverse output")

    parser.add_argument(
        "-m", "--min-length", default=5, help="minimum token length", type=int
    )

    parser.add_argument(
        "--warn-empty", action="store_true", help="warn if result is empty"
    )

    main(parser)
