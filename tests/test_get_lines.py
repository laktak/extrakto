#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

from extrakto import get_lines


class TestGetLines(unittest.TestCase):

    def test_get_lines_of_min_length(self):
        text = """\
first line
   second line with whitespace
short"""
        words = [
            "first line", "second line with whitespace",
        ]

        result = get_lines(text, 6)
        self.assertEquals(words, result)


if __name__ == '__main__':
    unittest.main()
