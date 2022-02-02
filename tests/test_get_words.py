#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from extrakto import Extrakto

get_words = Extrakto(min_length=5)["word"].filter


class TestGetWords(unittest.TestCase):
    def test_skip_dot_last_word_in_sentence(self):
        text = "Hello world. Extrakto is an awesome plugin."
        words = ["Hello", "world", "Extrakto", "awesome", "plugin"]

        result = get_words(text)
        self.assertEqual(words, result)

    def test_box_drawing(self):
        text = "other│something"
        words = ["other", "something"]

        result = get_words(text)
        self.assertEqual(words, result)

    def test_match_hidden_files(self):
        text = "one /home/user/.hidden.txt two .hidden.txt three ./.hidden.txt four ../.hidden.txt"
        words = [
            "/home/user/.hidden.txt",
            ".hidden.txt",
            "three",
            "./.hidden.txt",
            "../.hidden.txt",
        ]

        result = get_words(text)
        self.assertEqual(words, result)


if __name__ == "__main__":
    unittest.main()
