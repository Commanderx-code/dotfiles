import fcntl
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


class WelcomeTests(unittest.TestCase):
    def test_config_keeps_the_four_tree_sections_and_ghost_row(self):
        modules = [module for module in BASE['modules'] if isinstance(module, dict)]
        headings = [m['key'] for m in modules if 'key' in m and not m['key'].startswith('│')]
        self.assertEqual(len(headings), 4)
        self.assertTrue(all('─' not in heading for heading in headings))
        self.assertTrue(any('󰮯' in module.get('format', '') for module in modules))

    @unittest.skipUnless(shutil.which('fastfetch'), 'Fastfetch required')
    def test_native_fastfetch_accepts_the_config(self):
        result = subprocess.run(['fastfetch', '--config', '-', '--logo', 'none', '--pipe', 'true'],
                                input=json.dumps(BASE), capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(result.stderr, result.stderr)
        for expected in ('DISTRO', 'Memory', 'Uptime', '󰮯'):
            self.assertIn(expected, result.stdout)

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
            for marker in (b'LAYOUT', b'Hello, ', b'DETAIL', b'STALE_REDRAW'):
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
