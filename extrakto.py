#!/usr/bin/env python3

import sys, re
from collections import OrderedDict

# for now only accept one option, get text from stdin

if len(sys.argv) != 2:
    print('Usage: extrakto OPTION')
    print('Extracts tokens from plaintext.')
    print()
    print('-p                         extract path tokens')
    print('-u                         extract url tokens')
    print()
    sys.exit(1)

CMD=sys.argv[1]
text=sys.stdin.read()

res=list()
if CMD == '-p':
    # extract path tokens

    # the regex works ok but could probably be improved
    # copycat's regex was not used as it does not allow for things like "(/path)"

    e = r'[ \t\n](?:"|\(|\[|<|\')?(~/|/)?([-a-zA-Z0-9_+-,.]+/[^ \t\n\r|:"\'$%&)>\]]*)'
    for m in re.finditer(e, "\n" + text):
        item=(m.group(1) or "") + m.group(2)
        if item[-1] == ',': item = item[:-1]
        # hack to exclude transfer speeds like 5k/s or m/s, and page 1/2
        if not re.search(r'[kmgKMG]/s$|^\d+/\d+$', item, re.I):
            res.append(item)

elif CMD == '-u':
    # extract urls

    e = r"(https?://|git@|git://|ssh://|ftp://|file:///)[a-zA-Z0-9?=%/_.:,;~@!#$&()*+-]*"
    for m in re.finditer(e, text):
        item = m.group()
        if item[-1] == ',' or item[-1] == ')': item = item[:-1] # possible markdown link
        res.append(item)
else:
    print('unknown option')
    sys.exit(1)

res.reverse()
for item in OrderedDict.fromkeys(res):
    print(item)

