#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
import subprocess
import os
import sys

class TestAssets(unittest.TestCase):

    def test_all(self):
        script_dir = os.path.dirname(os.path.realpath(__file__))
        tests = ['text1', 'text2', 'unicode']
        for test in tests:
            if (sys.version_info < (3, 0)):
                subprocess.check_call("cd '%s'; ../extrakto.py -w < assets/%s.txt | cmp - ./assets/%s_result.txt" %
                    (script_dir, test, test), shell=True)
            else:
                subprocess.run("../extrakto.py -w < assets/%s.txt | cmp - ./assets/%s_result.txt" %
                    (test, test), shell=True, check=True, cwd=script_dir)

if __name__ == '__main__':
    unittest.main()
