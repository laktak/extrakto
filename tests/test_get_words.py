#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

from extrakto import get_words


class TestGetWords(unittest.TestCase):

    def test_skip_dot_last_word_in_sentence(self):
        text = "Hello world. Extrakto is an awesome plugin."
        words = [
            "Hello", "world", "Extrakto", "awesome", "plugin"
        ]

        result = get_words(text, 4)
        self.assertEquals(words, result)

    def test_box_drawing(self):
        text = u"last│first"
        words = [
            "last", "first"
        ]

        result = get_words(text, 4)
        self.assertEquals(words, result)

    def test_match_hidden_files(self):
        text = "one /home/user/.hidden.txt two .hidden.txt three ./.hidden.txt four ../.hidden.txt"
        words = [
            "/home/user/.hidden.txt", ".hidden.txt", "./.hidden.txt",
            "../.hidden.txt"
        ]

        result = get_words(text, 6)
        self.assertEquals(words, result)


if __name__ == '__main__':
    unittest.main()
