import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location('clickpaste', Path(__file__).resolve().parents[1] / 'home-manager/scripts/clickpaste.py')
clickpaste = importlib.util.module_from_spec(spec)
spec.loader.exec_module(clickpaste)


class ClickpasteTests(unittest.TestCase):
    def test_clipboard_lines_cannot_become_input_commands(self):
        text = '  text with spaces\nkey ctrl+a\nclick left\t--literal\\text\n'
        self.assertEqual(clickpaste.dotool_actions(text),
                         b'type   text with spaces\nkey enter\ntype key ctrl+a\nkey enter\n'
                         b'type click left\nkey tab\ntype --literal\\text\nkey enter\n')

    def test_long_lines_are_chunked_without_losing_text(self):
        text = 'a' * 100000
        actions = clickpaste.dotool_actions(text).decode().splitlines()
        self.assertTrue(all(len(line) < 65536 for line in actions))
        self.assertEqual(''.join(line.removeprefix('type ') for line in actions), text)

    def test_windows_newlines_and_control_characters(self):
        self.assertEqual(clickpaste.dotool_actions('a\r\nb'), b'type a\nkey enter\ntype b\n')
        with self.assertRaises(ValueError):
            clickpaste.dotool_actions('hello\x1b[31m')

    def run_mocked(self, clipboard_status=0, check=False):
        with patch.dict(clickpaste.os.environ, {'XDG_SESSION_TYPE': 'wayland'}), \
             patch.object(clickpaste.shutil, 'which', return_value='/mock/tool'), \
             patch.object(clickpaste.os, 'access', return_value=True), \
             patch.object(clickpaste.time, 'sleep') as sleep, \
             patch.object(clickpaste.subprocess, 'run') as run:
            run.side_effect = [subprocess.CompletedProcess([], clipboard_status, b'one\ntwo\n', b''),
                               subprocess.CompletedProcess([], 0, b'', b'')]
            status = clickpaste.main(['--check'] if check else [])
            return status, run.call_args_list, sleep.call_count

    def test_clipboard_failure_never_types(self):
        status, calls, sleeps = self.run_mocked(clipboard_status=1)
        self.assertEqual((status, len(calls), sleeps), (1, 1, 0))

    def test_wayland_types_multiline_via_stdin(self):
        status, calls, sleeps = self.run_mocked()
        self.assertEqual((status, sleeps), (0, 1))
        self.assertEqual(calls[1].args[0], ['dotool'])
        self.assertEqual(calls[1].kwargs['input'], b'type one\nkey enter\ntype two\nkey enter\n')

    def test_check_does_not_read_or_type_clipboard(self):
        status, calls, sleeps = self.run_mocked(check=True)
        self.assertEqual((status, calls, sleeps), (0, [], 0))
