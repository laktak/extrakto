#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

from extrakto import get_paths


class TestGetPaths(unittest.TestCase):

    def test_match_tilde_path(self):
        text = "hey, test ~/tmp/test.txt etc..."
        urls = ["~/tmp/test.txt"]

        result = get_paths(text)
        self.assertEquals(urls, result)

    def test_match_full_path(self):
        text = "hey, open this file /home/joe/test.txt etc..."
        urls = ["/home/joe/test.txt"]

        result = get_paths(text)
        self.assertEquals(urls, result)


if __name__ == '__main__':
    unittest.main()
