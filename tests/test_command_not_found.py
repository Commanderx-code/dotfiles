import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'configs/fish/functions/fish_command_not_found.fish'


class MissingCommandTests(unittest.TestCase):
    def run_handler(self, answers='', interactive=True, tty=True, packages='extra/example', command='example'):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for name, content in {
                'pkgfile': '#!/bin/sh\nprintf "%s\\n" "$TEST_PACKAGES"\n',
                'pacman': '#!/bin/sh\nexit 0\n',
                'sudo': '#!/bin/sh\nprintf "INSTALL:%s\\n" "$*"\n',
            }.items():
                path = directory / name
                path.write_text(content)
                path.chmod(0o700)
            code = 'source "$argv[1]"; '
            if tty:
                code += 'function isatty; return 0; end; '
            code += 'fish_command_not_found "$argv[2]"'
            return subprocess.run(['fish', '--no-config', *(['-i'] if interactive else []), '-c', code, str(SOURCE), command],
                                  input=answers, capture_output=True, text=True,
                                  env=dict(os.environ, PATH=tmp+os.pathsep+os.environ['PATH'], TEST_PACKAGES=packages, TERM='xterm'))

    def test_decline_never_installs(self):
        result = self.run_handler('n\n')
        self.assertEqual(result.returncode, 127)
        self.assertIn('extra/example', result.stdout)
        self.assertNotIn('INSTALL:', result.stdout)

    def test_confirmation_installs_only_selected_package(self):
        result = self.run_handler('2\ny\n', packages='extra/first\nextra/second')
        self.assertEqual(result.returncode, 127)
        self.assertIn('INSTALL:pacman -S --needed -- extra/second', result.stdout)
        self.assertIn('Run your command again', result.stdout)

    def test_script_and_redirected_input_never_install(self):
        for interactive, tty in [(False, True), (True, False)]:
            with self.subTest(interactive=interactive):
                result = self.run_handler('y\n', interactive=interactive, tty=tty)
                self.assertEqual(result.returncode, 127)
                self.assertNotIn('INSTALL:', result.stdout)

    def test_invalid_selection_never_installs(self):
        result = self.run_handler('99\ny\n', packages='extra/first\nextra/second')
        self.assertEqual(result.returncode, 127)
        self.assertNotIn('INSTALL:', result.stdout)
