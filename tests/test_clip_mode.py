#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest


def build_clip_mode_cycle(order_string):
    """Build the next_clip_mode dictionary from an order string."""
    modes_list = order_string.split(" ")
    next_mode = {}
    for i in range(len(modes_list)):
        if i == len(modes_list) - 1:
            next_mode[modes_list[i]] = modes_list[0]
        else:
            next_mode[modes_list[i]] = modes_list[i + 1]
    return modes_list, next_mode


def get_next_clip_mode(current_mode, modes_list, next_mode):
    """Get the next clip mode in the cycle."""
    if current_mode in next_mode:
        return next_mode[current_mode]
    else:
        # fallback to first in list if current mode not in cycle
        return modes_list[0]


class TestClipModeCycle(unittest.TestCase):
    def test_default_order_cycle(self):
        """Test default order: bg -> tmux_osc52 -> buffer -> bg"""
        modes_list, next_mode = build_clip_mode_cycle("bg tmux_osc52 buffer")

        self.assertEqual(modes_list[0], "bg")
        self.assertEqual(next_mode["bg"], "tmux_osc52")
        self.assertEqual(next_mode["tmux_osc52"], "buffer")
        self.assertEqual(next_mode["buffer"], "bg")

    def test_custom_order_buffer_first(self):
        """Test custom order: buffer -> tmux_osc52 -> bg -> buffer"""
        modes_list, next_mode = build_clip_mode_cycle("buffer tmux_osc52 bg")

        self.assertEqual(modes_list[0], "buffer")
        self.assertEqual(next_mode["buffer"], "tmux_osc52")
        self.assertEqual(next_mode["tmux_osc52"], "bg")
        self.assertEqual(next_mode["bg"], "buffer")

    def test_two_modes_only(self):
        """Test with only two modes: buffer -> tmux_osc52 -> buffer"""
        modes_list, next_mode = build_clip_mode_cycle("buffer tmux_osc52")

        self.assertEqual(len(modes_list), 2)
        self.assertEqual(modes_list[0], "buffer")
        self.assertEqual(next_mode["buffer"], "tmux_osc52")
        self.assertEqual(next_mode["tmux_osc52"], "buffer")

    def test_single_mode_no_cycle(self):
        """Test with single mode - cycles back to itself"""
        modes_list, next_mode = build_clip_mode_cycle("buffer")

        self.assertEqual(len(modes_list), 1)
        self.assertEqual(modes_list[0], "buffer")
        self.assertEqual(next_mode["buffer"], "buffer")

    def test_get_next_mode_in_cycle(self):
        """Test getting next mode when current is in cycle"""
        modes_list, next_mode = build_clip_mode_cycle("buffer tmux_osc52 bg")

        self.assertEqual(get_next_clip_mode("buffer", modes_list, next_mode), "tmux_osc52")
        self.assertEqual(get_next_clip_mode("tmux_osc52", modes_list, next_mode), "bg")
        self.assertEqual(get_next_clip_mode("bg", modes_list, next_mode), "buffer")

    def test_get_next_mode_not_in_cycle(self):
        """Test fallback to first mode when current is not in cycle"""
        modes_list, next_mode = build_clip_mode_cycle("buffer tmux_osc52")

        # "bg" is not in the cycle, should fallback to first (buffer)
        self.assertEqual(get_next_clip_mode("bg", modes_list, next_mode), "buffer")
        self.assertEqual(get_next_clip_mode("fg", modes_list, next_mode), "buffer")

    def test_full_cycle_iteration(self):
        """Test iterating through a full cycle"""
        modes_list, next_mode = build_clip_mode_cycle("buffer tmux_osc52 bg")

        current = modes_list[0]  # Start with default (buffer)
        visited = [current]

        # Cycle through all modes
        for _ in range(len(modes_list)):
            current = get_next_clip_mode(current, modes_list, next_mode)
            visited.append(current)

        # Should have visited: buffer -> tmux_osc52 -> bg -> buffer
        self.assertEqual(visited, ["buffer", "tmux_osc52", "bg", "buffer"])

    def test_fg_mode_in_cycle(self):
        """Test with fg mode instead of bg"""
        modes_list, next_mode = build_clip_mode_cycle("buffer tmux_osc52 fg")

        self.assertEqual(modes_list[0], "buffer")
        self.assertEqual(next_mode["buffer"], "tmux_osc52")
        self.assertEqual(next_mode["tmux_osc52"], "fg")
        self.assertEqual(next_mode["fg"], "buffer")


if __name__ == "__main__":
    unittest.main()
