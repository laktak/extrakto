#!/usr/bin/env python3

import unittest
import subprocess
import os
import sys

script_dir = os.path.dirname(os.path.realpath(__file__))


def run_test(switch, name):
    subprocess.run(
        f"../extrakto.py {switch} < assets/{name}.txt | cmp - ./assets/{name}_result{switch}.txt",
        shell=True,
        check=True,
        cwd=script_dir,
    )


class TestAssets(unittest.TestCase):
    def test_all(self):
        for test in ["text1", "text2", "path", "unicode", "quotes"]:
            run_test("-w", test)

        for test in ["text1", "path"]:
            run_test("-pu", test)


if __name__ == "__main__":
    unittest.main()
