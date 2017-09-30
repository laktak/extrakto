#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

from extrakto import get_urls


class TestGetURLs(unittest.TestCase):

    def test_match_http(self):
        text = "hey, open this url http://google.com etc..."
        urls = ["http://google.com"]

        result = get_urls(text)
        self.assertEquals(urls, result)

    def test_match_https(self):
        text = "hey, open this secure url https://google.com etc..."
        urls = ["https://google.com"]

        result = get_urls(text)
        self.assertEquals(urls, result)

    def test_match_ftp(self):
        text = "hey, connect to this server ftp://myserver.com etc..."
        urls = ["ftp://myserver.com"]

        result = get_urls(text)
        self.assertEquals(urls, result)

    def test_match_sftp(self):
        text = "hey, connect to this secure server sftp://myserver.com etc..."
        urls = ["sftp://myserver.com"]

        result = get_urls(text)
        self.assertEquals(urls, result)

    def test_match_home_path(self):
        text = "hey, open this file file:////home/joe etc..."
        urls = ["file:////home/joe"]

        result = get_urls(text)
        self.assertEquals(urls, result)

    def test_match_git(self):
        text = ("hey, check out this repo git@github.com:laktak/extrakto.git"
                ", it's a great tmux plugin")
        urls = ["git@github.com:laktak/extrakto.git"]

        result = get_urls(text)
        self.assertEquals(urls, result)

    def test_match_HTTP(self):
        text = "hey, open this url HTTP://GOOGLE.COM etc..."
        urls = ["HTTP://GOOGLE.COM"]

        result = get_urls(text)
        self.assertEquals(urls, result)


if __name__ == '__main__':
    unittest.main()
