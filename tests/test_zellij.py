import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ZellijTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.bin = self.directory / 'bin'
        self.bin.mkdir()
        self.log = self.directory / 'calls'
        for name in ('zellij', 'zesh'):
            script = self.bin / name
            script.write_text('#!/bin/sh\nprintf "%s\\n" "$0" "$@" >> "$TEST_LOG"\n')
            script.chmod(0o755)
        fzf = self.bin / 'fzf'
        fzf.write_text('#!/bin/sh\nexit 130\n')
        fzf.chmod(0o755)

    def run_fish(self, function, args=(), inside=False):
        env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'], TEST_LOG=str(self.log))
        env.pop('ZELLIJ', None)
        if inside:
            env['ZELLIJ'] = '1'
        return subprocess.run([shutil.which('fish'), '--no-config', '-c',
                               'source "$argv[1]"; set -l fn "$argv[2]"; $fn $argv[3..]',
                               str(ROOT / f'configs/fish/functions/{function}.fish'), function, *args],
                              env=env, cwd=self.directory, text=True, capture_output=True)

    def test_picker_cancellation_does_not_start_session(self):
        result = self.run_fish('zwork')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), [str(self.bin / 'zesh'), 'list'])

    def test_existing_session_switch_never_nests(self):
        for inside in (False, True):
            self.log.unlink(missing_ok=True)
            result = self.run_fish('zwork', ['my session'], inside)
            self.assertEqual(result.returncode, 0, result.stderr)
            expected = ['action', 'switch-session', '--', 'my session'] if inside else ['connect', '--', 'my session']
            self.assertEqual(self.log.read_text().splitlines()[1:], expected)

    def test_project_subdirectories_use_repo_root_and_quote_spaces(self):
        project = self.directory / 'project with spaces'
        child = project / 'src'
        child.mkdir(parents=True)
        subprocess.run(['git', 'init', '-q', str(project)], check=True)
        for inside in (False, True):
            self.log.unlink(missing_ok=True)
            result = self.run_fish('zwork', [str(child)], inside)
            self.assertEqual(result.returncode, 0, result.stderr)
            expected = ['action', 'switch-session', '--cwd', str(project), '--', project.name] if inside else ['connect', '--', str(project)]
            self.assertEqual(self.log.read_text().splitlines()[1:], expected)

    def test_development_layout_adds_tab_when_inside(self):
        for inside in (False, True):
            self.log.unlink(missing_ok=True)
            result = self.run_fish('zdev', inside=inside)
            self.assertEqual(result.returncode, 0, result.stderr)
            expected = ['action', 'new-tab', '--layout', 'commander-dev', '--cwd', str(self.directory)] if inside else ['--layout', 'commander-dev']
            self.assertEqual(self.log.read_text().splitlines()[1:], expected)

    def test_welcome_is_quiet_in_zellij(self):
        script = ROOT / 'configs/fish/conf.d/fastfetch.fish'
        result = subprocess.run(['fish', '--no-config', '-i', '-c', 'source "$argv[1]"', str(script)],
                                env=dict(os.environ, ZELLIJ='1', TERM_PROGRAM='ghostty', TERM='xterm-256color'),
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '')
