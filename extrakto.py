#!/usr/bin/env python

import sys, re, argparse
from collections import OrderedDict

parser = argparse.ArgumentParser(description='Extracts tokens from plaintext.')
parser.add_argument('-p', help='extract path tokens', action='store_true')
parser.add_argument('-u', help='extract url tokens', action='store_true')
parser.add_argument('-w', help='extract word tokens', action='store_true')
parser.add_argument('-r', help='reverse output', action='store_true')
parser.add_argument('-m', '--min-length', help='minimum token length', default=5)
args = parser.parse_args()

# regexes fro extraction
REPATH = r'(?=[ \t\n]|"|\(|\[|<|\')?(~/|/)?([-a-zA-Z0-9_+-,.]+/[^ \t\n\r|:"\'$%&)>\]]*)'
REURL = r"(https?://|git@|git://|ssh://|ftp://|file:///)[a-zA-Z0-9?=%/_.:,;~@!#$&()*+-]*"
REWORD = r'[^][(){} \t\n\r]+'

def processUP(find, text, ml):
    res=list()
    for m in re.finditer(find, "\n" + text):
        item=m.group()
        if item[-1] == ',' or item[-1] == ')': item = item[:-1] # possible markdown link
        # hack to exclude transfer speeds like 5k/s or m/s, and page 1/2
        if not re.search(r'[kmgKMG]/s$|^\d+/\d+$', item, re.I):
            if len(item) > ml: res.append(item)
    return res

def processW(find, text, ml):
    res=list()
    for m in re.finditer(find, "\n" + text):
        item=m.group().strip(',.:;()[]{}<>\'"')
        if len(item) > ml: res.append(item)
    return res

def getInput():
    return sys.stdin.read()

if args.w:
    # extract words
    res = processW(REWORD, getInput(), args.min_length)

elif args.p:
    # extract path tokens
    if args.u: res = processUP(REPATH + "|" + REURL, getInput(), args.min_length)
    else: res = processUP(REPATH, getInput(), args.min_length)

elif args.u:
    # extract urls
    res = processUP(REURL, getInput(), args.min_length)

else:
    print('unknown option, see --help')
    sys.exit(1)

if args.r: res.reverse()

# remove duplicates and print
for item in OrderedDict.fromkeys(res):
    print(item)


