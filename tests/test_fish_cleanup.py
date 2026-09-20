"""Regression checks for shell helpers; all external actions use fixtures."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
FUNCTIONS = ROOT / 'configs/fish/functions'
FISH = shutil.which('fish')


class FishCleanupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='fish-cleanup-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'calls'
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                        TEST_LOG=str(self.log), TMPDIR=str(self.root))

    def mock(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/sh\n' + body + '\n')
        path.chmod(0o755)

    def run_fish(self, code, *args):
        return subprocess.run([FISH, '--no-config', '-c',
                               'set -p fish_function_path $argv[1]; set -e argv[1]; ' + code,
                               str(FUNCTIONS), *args], env=self.env, cwd=self.root,
                              capture_output=True, text=True, timeout=15)

    def test_help_lists_command_names_with_color_formatting(self):
        result = self.run_fish('helpme')
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in ('fastfetch', 'starship', 'config-index', 'backup-everything', 'full-upgrade', ':Lazy'):
            self.assertIn(name, result.stdout)

    def test_environment_preserves_overrides_and_does_not_write_universal_go_values(self):
        self.env.update(XDG_CONFIG_HOME=str(self.root / 'config'),
                        XDG_DATA_HOME=str(self.root / 'data'),
                        GOPATH=str(self.root / 'custom-go'), GOBIN=str(self.root / 'custom-bin'))
        result = self.run_fish('function dotfiles-settings; end; source "$argv[1]"; '
                               'printf "%s\\n" "$XDG_DATA_HOME" "$GOPATH" "$GOBIN"; '
                               'set -qU GOPATH; and exit 42; set -qU GOBIN; and exit 42; exit 0',
                               str(ROOT / 'configs/fish/conf.d/exports.fish'))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(),
                         [self.env['XDG_DATA_HOME'], self.env['GOPATH'], self.env['GOBIN']])

    def test_lazyg_checks_arguments_and_stops_on_git_failures(self):
        self.mock('git', 'printf "%s\\n" "$*" >> "$TEST_LOG"\n'
                  '[ "$1" != "$TEST_FAIL" ] || exit 42')
        result = self.run_fish('lazyg')
        self.assertEqual(result.returncode, 1)
        self.assertFalse(self.log.exists())
        for failure, expected in [('add', ['add .']),
                                  ('commit', ['add .', 'commit -m two words']),
                                  ('push', ['add .', 'commit -m two words', 'push']),
                                  ('', ['add .', 'commit -m two words', 'push'])]:
            with self.subTest(failure=failure):
                self.log.unlink(missing_ok=True)
                self.env['TEST_FAIL'] = failure
                result = self.run_fish('lazyg "two words"')
                self.assertEqual(result.returncode, 42 if failure else 0, result.stderr)
                self.assertEqual(self.log.read_text().splitlines(), expected)

    def test_upgrade_runs_one_system_updater_and_stops_on_failure(self):
        # Restrict PATH so the real Paru/Pacman/Flatpak cannot run, even for fallback.
        self.env['PATH'] = str(self.bin)
        for name in ('paru', 'sudo', 'flatpak'):
            self.mock(name, f'printf "%s\\n" "{name} $*" >> "$TEST_LOG"\n'
                      f'[ "$TEST_FAIL" != "{name}" ] || exit 42')
        for fail, expected in [('', ['paru -Syu', 'flatpak update -y']),
                               ('paru', ['paru -Syu']),
                               ('flatpak', ['paru -Syu', 'flatpak update -y'])]:
            self.env['TEST_FAIL'] = fail
            self.log.unlink(missing_ok=True)
            result = self.run_fish('upgrade')
            self.assertEqual(result.returncode, 42 if fail else 0, result.stderr)
            self.assertEqual(self.log.read_text().splitlines(), expected)
        (self.bin / 'paru').unlink()
        self.env['TEST_FAIL'] = ''
        self.log.unlink()
        result = self.run_fish('upgrade')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), ['sudo pacman -Syu', 'flatpak update -y'])

    def test_mkcd_stops_when_creation_fails(self):
        self.mock('mkdir', 'exit 42')
        target = self.root / 'already exists'
        target.mkdir()
        result = self.run_fish('mkcd "$argv[1]"; set -l result $status; pwd; exit $result', str(target))
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.root))

    def test_broot_cleans_temp_file_without_trash_and_preserves_failure(self):
        self.mock('broot', 'printf "%s" "$2" > "$TEST_LOG"\n'
                  'printf "/bin/false\\n" > "$2"\nexit "${TEST_BROOT_STATUS:-0}"')
        for status, expected in [('0', 1), ('42', 42)]:
            self.env['TEST_BROOT_STATUS'] = status
            result = self.run_fish('function rm; echo TRASH_CALLED; return 99; end; br')
            self.assertEqual(result.returncode, expected, result.stderr)
            self.assertNotIn('TRASH_CALLED', result.stdout)
            self.assertFalse(Path(self.log.read_text()).exists())

    def test_spotatui_consumes_marker_without_trash(self):
        marker = self.root / 'spotatui-autostart'
        marker.touch()
        self.mock('spotatui', 'printf started > "$TEST_LOG"')
        self.env.update(XDG_RUNTIME_DIR=str(self.root), TERM_PROGRAM='ghostty')
        result = self.run_fish('function rm; echo TRASH_CALLED; return 99; end; source "$argv[1]"',
                               str(ROOT / 'configs/fish/conf.d/spotatui-autostart.fish'))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('TRASH_CALLED', result.stdout)
        self.assertFalse(marker.exists())
        self.assertEqual(self.log.read_text(), 'started')

    def test_tab_calls_widget_as_function_and_preserves_normal_completion(self):
        code = '''function commandline
    if test (count $argv) -eq 1
        printf '%s' "$TEST_TOKEN"
    else
        printf '%s\\n' "$argv" >> "$TEST_LOG"
    end
end
function fzf-file-widget; echo WIDGET; end
__fzf_starstar_tab
'''
        self.env['TEST_TOKEN'] = 'folder with spaces/**'
        result = self.run_fish(code)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'WIDGET')
        self.assertIn('folder with spaces/', self.log.read_text())
        self.env['TEST_TOKEN'] = 'ordinary'
        self.log.unlink()
        result = self.run_fish(code)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('WIDGET', result.stdout)
        self.assertIn('complete', self.log.read_text())

    def test_directory_pickers_preserve_unusual_paths_and_cancel(self):
        target = self.root / 'space and\nnewline'
        target.mkdir()
        self.env['TEST_PICK'] = str(target)
        self.mock('fd', 'printf "%s\\n" "$*" >> "$TEST_LOG"\nprintf "%s\\0" "$TEST_PICK"')
        self.mock('fzf', '/bin/cat')
        for function, option in [('fcd', '--max-depth 1'), ('cdi', '--hidden --follow')]:
            result = self.run_fish(function + '; printf "%s" "$PWD"')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, str(target))
            self.assertIn(option, self.log.read_text())
        self.mock('fzf', 'exit 130')
        result = self.run_fish('cdi; pwd')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.root))

    def test_config_index_reads_page_status_and_opens_selected_document(self):
        docs = self.root / 'bible/docs'
        docs.mkdir(parents=True)
        page = docs / 'example page.md'
        page.write_text('---\ntitle: Example\ncategory: Shell\nstatus: active\n'
                        'criticality: normal\ntags: example\n---\n# Example\n')
        self.env['CONFIG_BIBLE_HOME'] = str(docs.parent)
        self.mock('fzf', '/bin/cat > "$TEST_LOG"\nprintf "enter\\n"\n/bin/cat "$TEST_LOG"')
        self.mock('nvim', 'printf "%s\\n" "$*"')
        result = self.run_fish('function dotfiles-settings; end; config-index')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        self.assertIn(str(page), result.stdout)
        self.assertEqual(self.log.read_text().split('\t')[3], 'active')


if __name__ == '__main__':
    unittest.main()
