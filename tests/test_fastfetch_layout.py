import fcntl
import importlib.util
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('fastfetch_layout', ROOT / 'home-manager/scripts/fastfetch-layout.py')
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)
BASE = json.loads((ROOT / 'configs/fastfetch/config.jsonc').read_text())


def visible_test_screen(data):
    """Replay the cursor/erase operations used by the ASCII prompt fixture.

    Checking raw output alone misses rows subsequently erased by Fish repaint.
    This intentionally isn't a general-purpose terminal emulator.
    """
    text = data.decode(errors='replace')
    text = re.sub(r'\x1b(?:\].*?(?:\x07|\x1b\\)|P.*?\x1b\\)', '', text, flags=re.S)
    cells = {}
    row = column = 0
    for token in re.findall(r'\x1b\[[0-?]*[ -/]*[@-~]|\x1b.|[^\x1b]', text):
        if token.startswith('\x1b['):
            code = token[-1]
            values = token[2:-1]
            if values and not re.fullmatch(r'[\d;]*', values):
                continue
            args = [int(value or 0) for value in values.split(';')]
            n = args[0] or 1
            if code == 'A':
                row = max(0, row - n)
            elif code == 'B':
                row += n
            elif code == 'C':
                column += n
            elif code == 'D':
                column = max(0, column - n)
            elif code in ('H', 'f'):
                row = n - 1
                column = (args[1] or 1) - 1 if len(args) > 1 else 0
            elif code == 'K':
                cells = {p: c for p, c in cells.items() if p[0] != row or p[1] < column}
            elif code == 'J':
                cells = {} if args[0] == 2 else {p: c for p, c in cells.items() if p < (row, column)}
        elif token.startswith('\x1b'):
            continue
        elif token == '\r':
            column = 0
        elif token == '\n':
            row += 1
        elif token == '\b':
            column = max(0, column - 1)
        elif token >= ' ':
            cells[row, column] = token
            column += 1
    return '\n'.join(''.join(cells.get((y, x), ' ') for x in range(200)).rstrip()
                     for y in range(max((p[0] for p in cells), default=0) + 1))


class LayoutTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('fish'), 'Fish required')
    def test_default_wrapper_preserves_native_config_and_arguments(self):
        fish = shutil.which('fish')
        wrapper = ROOT / 'configs/fish/functions/fastfetch.fish'
        with tempfile.TemporaryDirectory(prefix='fastfetch-native-') as directory:
            executable = Path(directory) / 'fastfetch'
            executable.write_text('#!/usr/bin/env python3\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\n')
            executable.chmod(0o755)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ['PATH'])
            for args in ([], ['--config', '/tmp/custom preset.jsonc', '--logo', 'none']):
                result = subprocess.run([fish, '--no-config', '-c',
                                         'function isatty; return 0; end; source $argv[1]; fastfetch $argv[2..-1]',
                                         '--', str(wrapper), *args],
                                        env=env, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout), args)

    def test_layouts_remove_fixed_cursor_positions_and_borders(self):
        for columns, rows in [(40, 20), (60, 30), (100, 27), (200, 60)]:
            config = renderer.layout(BASE, columns, rows)
            for module in config['modules']:
                self.assertNotIn('\x1b', module.get('key', '') + module.get('format', ''))
                self.assertNotIn('╮', module.get('format', ''))
            self.assertFalse(config['display']['disableLinewrap'])

    def test_normal_window_stacks_logo_without_shrinking_it(self):
        config = renderer.layout(BASE, 100, 27)
        self.assertEqual(config['logo']['width'], 24)
        self.assertEqual(config['logo']['position'], 'top')
        self.assertNotIn('height', config['logo'])
        self.assertEqual(config['modules'][0], {'type': 'custom', 'format': '\r'})
        self.assertNotIn('bottom', config['logo']['padding'])

    def test_section_dividers_do_not_fill_the_old_window_width(self):
        for columns in (40, 100, 190):
            config = renderer.layout(BASE, columns, 40)
            headings = [m['format'] for m in config['modules'] if '──' in m.get('format', '')]
            self.assertEqual(len(headings), 5)
            self.assertTrue(all('───' not in heading for heading in headings))

    def test_every_window_keeps_all_fields_and_palette(self):
        originals = [module for module in BASE['modules']
                     if isinstance(module, dict) and module['type'] != 'custom']
        for columns, rows in [(30, 12), (80, 24), (100, 27), (100, 40), (190, 40), (200, 60)]:
            config = renderer.layout(BASE, columns, rows)
            fields = [module for module in config['modules'] if module['type'] != 'custom']
            self.assertEqual([m['type'] for m in fields], [m['type'] for m in originals])
            self.assertEqual([m.get('format') for m in fields], [m.get('format') for m in originals])
            self.assertTrue(any('󰮯' in module.get('format', '') for module in config['modules']))

    def test_height_does_not_change_information(self):
        self.assertEqual(renderer.layout(BASE, 100, 24)['modules'],
                         renderer.layout(BASE, 100, 60)['modules'])

    def test_tiny_pane_omits_only_image(self):
        config = renderer.layout(BASE, 30, 12)
        self.assertEqual(config['logo']['type'], 'none')
        self.assertIn('memory', [module['type'] for module in config['modules']])
        self.assertIn('uptime', [module['type'] for module in config['modules']])

    def test_full_layout_keeps_details_and_original_config_is_unchanged(self):
        config = renderer.layout(BASE, 200, 60)
        self.assertEqual(config['logo']['position'], 'left')
        self.assertIn('icons', [module['type'] for module in config['modules']])
        self.assertIn('player', [module['type'] for module in config['modules']])
        self.assertNotIn('height', BASE['logo'])

    @unittest.skipUnless(shutil.which('fastfetch'), 'Fastfetch required')
    def test_native_fastfetch_accepts_generated_layouts(self):
        for columns, rows in [(40, 20), (100, 27), (200, 60)]:
            config = renderer.layout(BASE, columns, rows)
            result = subprocess.run(['fastfetch', '--config', '-', '--logo', 'none', '--pipe', 'true'],
                                    input=json.dumps(config), capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(result.stderr, result.stderr)
            self.assertIn('OS', result.stdout)
            self.assertIn('Memory', result.stdout)
            self.assertIn('Uptime', result.stdout)
            self.assertIn('colors', result.stdout)

    @unittest.skipUnless(shutil.which('fish'), 'Fish required')
    def test_resize_never_reprints_welcome(self):
        self.check_resize(shutil.which('fish'))

    @unittest.skipUnless(Path('/usr/bin/fish').exists(), 'System Fish required')
    def test_system_fish_resize_never_reprints_welcome(self):
        self.check_resize('/usr/bin/fish')

    def check_resize(self, fish):
        # The welcome checks for an external binary before calling our Fish stub.
        # CI need not install Fastfetch just to exercise terminal redraw behavior.
        fixture = tempfile.TemporaryDirectory(prefix='welcome-command-')
        self.addCleanup(fixture.cleanup)
        executable = Path(fixture.name) / 'fastfetch'
        executable.write_text('#!/bin/sh\nexit 0\n')
        executable.chmod(0o755)
        master, slave = pty.openpty()
        self.addCleanup(os.close, master)
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 27, 100, 0, 0))
        source = ROOT / 'configs/fish/conf.d/fastfetch.fish'
        init = ("function fish_prompt; printf '\\nPOWERLINE\\nTEST_PROMPT> '; end; "
                "function fastfetch; set -l grid (stty size | string split ' '); printf 'LAYOUT %s %s\\n' $grid[2] $grid[1]; for n in (seq 50); printf 'DETAIL %s\\n' $n; end; printf 'MEMORY_MARKER\\nUPTIME_MARKER\\nCOLORS_MARKER\\n'; end; "
                "function __commander_welcome_resize --on-signal WINCH; printf 'STALE_REDRAW\\n'; end; "
                f"source '{source}'")
        proc = subprocess.Popen([fish, '--no-config', '-i', '-C', init],
                                stdin=slave, stdout=slave, stderr=slave,
                                env=dict(os.environ, TERM='xterm-256color', TERM_PROGRAM='ghostty',
                                         PATH=fixture.name + os.pathsep + os.environ['PATH']),
                                start_new_session=True,
                                preexec_fn=lambda: fcntl.ioctl(0, termios.TIOCSCTTY, 0))
        os.close(slave)
        def cleanup():
            if proc.poll() is None:
                proc.kill()
            proc.wait(timeout=5)
        self.addCleanup(cleanup)

        def read_chunk():
            chunk = os.read(master, 65536)
            # Minimal terminal replies for Fish's startup and prompt probes.
            if b'\x1b[0c' in chunk:
                os.write(master, b'\x1b[?1;2c')
            if b'\x1b[6n' in chunk:
                os.write(master, b'\x1b[1;1R')
            return chunk

        def read_until(marker, timeout=4):
            data = b''
            end = time.monotonic() + timeout
            while time.monotonic() < end:
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        data += read_chunk()
                    except OSError:
                        break
                    if marker in data:
                        return data
            self.fail(f'Timed out waiting for {marker!r} (exit={proc.poll()}): {data!r}')

        first = read_until(b'TEST_PROMPT>')
        self.assertIn(b'LAYOUT 100 27', first)
        self.assertEqual(first.count(b'LAYOUT'), 1)
        screen = visible_test_screen(first)
        for marker in ('MEMORY_MARKER', 'UPTIME_MARKER', 'COLORS_MARKER'):
            self.assertIn(marker, screen)
        for rows, columns in [(24, 80), (40, 190), (27, 100)]:
            fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', rows, columns, 0, 0))
            os.kill(proc.pid, signal.SIGWINCH)
            # Fish may only query the cursor, not repaint an unchanged prompt.
            # Observe the resize interval without demanding new prompt output.
            resized = b''
            end = time.monotonic() + 0.25
            while time.monotonic() < end:
                if select.select([master], [], [], 0.05)[0]:
                    resized += read_chunk()
            self.assertNotIn(b'\x1b[2J', resized)
            for marker in (b'LAYOUT', b'Hello, Commander', b'DETAIL', b'STALE_REDRAW'):
                self.assertNotIn(marker, resized)
        os.write(master, b"printf 'WORK_RETAINED\\n'\n")
        read_until(b'WORK_RETAINED\r\n')
        # Drain the prompt before the next resize.
        while select.select([master], [], [], 0.1)[0]:
            read_chunk()
        fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', 20, 60, 0, 0))
        os.kill(proc.pid, signal.SIGWINCH)
        time.sleep(0.1)
        os.write(master, b"printf 'AFTER_RESIZE\\n'\n")
        after = read_until(b'AFTER_RESIZE\r\n')
        self.assertNotIn(b'\x1b[2J', after)
        self.assertNotIn(b'LAYOUT', after)
