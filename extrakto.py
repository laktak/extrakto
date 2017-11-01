#!/usr/bin/env python

import sys
import re

from argparse import ArgumentParser
from collections import OrderedDict

RE_PATH = (
    r'(?=[ \t\n]|"|\(|\[|<|\')?'
    '(~/|/)?'
    '([-a-zA-Z0-9_+-,.]+/[^ \t\n\r|:"\'$%&)>\]]*)'
)

RE_URL = (r"(https?://|git@|git://|ssh://|s*ftp://|file:///)"
          "[a-zA-Z0-9?=%/_.:,;~@!#$&()*+-]*")

RE_URL_OR_PATH = RE_PATH + "|" + RE_URL

RE_WORD = r'[^][(){} \t\n\r]+'

# reg exp to exclude transfer speeds like 5k/s or m/s, and page 1/2
RE_SPEED = r'[kmgKMG]/s$|^\d+/\d+$'


def get_args():
    parser = ArgumentParser(description='Extracts tokens from plaintext.')

    parser.add_argument('-p', '--paths', action='store_true',
                        help='extract path tokens')

    parser.add_argument('-u', '--urls', action='store_true',
                        help='extract url tokens')

    parser.add_argument('-w', '--words', action='store_true',
                        help='extract word tokens')

    parser.add_argument('-r', '--reverse', action='store_true',
                        help='reverse output')

    parser.add_argument('-m', '--min-length', default=5,
                        help='minimum token length')

    args = parser.parse_args()

    return args


def process_urls_and_paths(find, text, ml):
    res = list()

    for m in re.finditer(find, "\n" + text, flags=re.I):
        item = m.group()
        # remove invalid end charaters (like punctuation
        # or markdown syntax)
        if item[-1] in ",):":
            item = item[:-1]

        # exclude transfer speeds like 5k/s or m/s, and page 1/2
        if not re.search(RE_SPEED, item, re.I):
            if len(item) > ml:
                res.append(item)
    return res


def get_urls(text, ml=0):
    return process_urls_and_paths(RE_URL, text, ml)


def get_paths(text, ml=0):
    return process_urls_and_paths(RE_PATH, text, ml)


def get_urls_or_paths(text, ml=0):
    return process_urls_and_paths(RE_URL_OR_PATH, text, ml)


def get_words(text, ml):
    words = []

    for m in re.finditer(RE_WORD, "\n" + text):
        item = m.group().strip(',:;()[]{}<>\'"|').rstrip('.')
        if len(item) > ml:
            words.append(item)

    return words


def get_input():
    return sys.stdin.read()


def main():
    args = get_args()

    if args.words:
        res = get_words(get_input(), args.min_length)

    elif args.paths:
        if args.urls:
            res = get_urls_or_paths(get_input(), args.min_length)
        else:
            res = get_paths(get_input(), args.min_length)

    elif args.urls:
        res = get_urls(get_input(), args.min_length)

    else:
        print('unknown option, see --help')
        sys.exit(1)

    if args.reverse:
        res.reverse()

    # remove duplicates and print
    for item in OrderedDict.fromkeys(res):
        print(item)


if __name__ == "__main__":
    main()
