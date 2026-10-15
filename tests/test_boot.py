"""restore-grub installs the repository's boot settings without touching the system."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'home-manager/scripts/restore-grub.sh'
SOURCE = ROOT / 'grub/grub'


class RestoreGrubTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='restore-grub-'))
        self.addCleanup(shutil.rmtree, self.tmp)
        binaries = self.tmp / 'bin'
        binaries.mkdir()
        # sudo runs its command as this user; pacman reports the theme installed;
        # update-grub records that it was called.
        (binaries / 'sudo').write_text('#!/bin/sh\nexec "$@"\n')
        (binaries / 'pacman').write_text('#!/bin/sh\nexit 0\n')
        (binaries / 'update-grub').write_text('#!/bin/sh\necho called >> "$GRUB_UPDATE_LOG"\n')
        for path in binaries.iterdir():
            path.chmod(0o755)
        self.grub = self.tmp / 'etc/default/grub'
        self.grub.parent.mkdir(parents=True)
        self.log = self.tmp / 'update.log'
        root = self.tmp / 'root'
        self.themes = root / 'usr/share/grub/themes'
        (self.themes / 'garuda-dr460nized').mkdir(parents=True)
        (self.themes / 'garuda-dr460nized/theme.txt').write_text('')
        (root / 'boot').mkdir()
        (root / 'boot/vmlinuz-linux-garuda').write_text('')
        # No machine choice in ~/.config/dotfiles/boot-theme, so grub/theme decides.
        self.env = dict(os.environ, PATH=f'{binaries}:{os.environ["PATH"]}', DOTFILES_DIR=str(ROOT),
                        GRUB_DEFAULT_FILE=str(self.grub), GRUB_THEME_ROOT=str(root), GRUB_THEMES_DIR=str(self.themes),
                        GRUB_UPDATE_LOG=str(self.log), XDG_CONFIG_HOME=str(self.tmp / 'config'))

    def run_script(self, *args):
        return subprocess.run(['bash', str(SCRIPT), *args], env=self.env, capture_output=True, text=True, check=True)

    def test_settings_are_installed_verbatim_with_a_backup_once(self):
        self.grub.write_text('GRUB_DEFAULT=0\nGRUB_THEME="/usr/share/grub/themes/cachyos/theme.txt"\n')
        result = self.run_script()
        self.assertEqual(self.grub.read_text(), SOURCE.read_text())
        backup = self.grub.with_name('grub.before-dotfiles')
        self.assertEqual(backup.read_text(), 'GRUB_DEFAULT=0\nGRUB_THEME="/usr/share/grub/themes/cachyos/theme.txt"\n')
        self.assertEqual(self.log.read_text(), 'called\n')
        self.assertEqual(result.stderr, '')
        # A second run changes nothing, keeps the first backup and says so.
        result = self.run_script()
        self.assertIn('already current', result.stdout)
        self.assertEqual(backup.read_text(), 'GRUB_DEFAULT=0\nGRUB_THEME="/usr/share/grub/themes/cachyos/theme.txt"\n')

    def test_the_cachyos_look_installs_the_theme_and_names_it(self):
        self.grub.write_text('GRUB_DEFAULT=0\n')
        (self.themes / 'cachyos').mkdir()
        (self.themes / 'cachyos/theme.txt').write_text('')
        result = self.run_script('cachyos')
        expected = SOURCE.read_text().replace('GRUB_THEME="/usr/share/grub/themes/garuda-dr460nized/theme.txt"',
                                              'GRUB_THEME="/usr/share/grub/themes/cachyos/theme.txt"')
        self.assertNotEqual(expected, SOURCE.read_text())
        self.assertEqual(self.grub.read_text(), expected)
        self.assertEqual((self.themes / 'cachyos/background.png').read_bytes(), (ROOT / 'grub/themes/cachyos/background.png').read_bytes())
        self.assertTrue((self.themes / 'cachyos/icons/garuda.png').is_file())
        self.assertIn('Boot menu look: cachyos', result.stdout)
        self.assertEqual(result.stderr, '')
        # The machine's remembered choice applies when no argument is given.
        (self.tmp / 'config/dotfiles').mkdir(parents=True)
        (self.tmp / 'config/dotfiles/boot-theme').write_text('cachyos\n')
        self.assertIn('already current', self.run_script().stdout)
        with self.assertRaises(subprocess.CalledProcessError):
            self.run_script('neon')

    def test_the_settings_turn_apparmor_on_and_name_the_theme(self):
        text = SOURCE.read_text()
        self.assertRegex(text, r'(?m)^GRUB_CMDLINE_LINUX_DEFAULT=".*lsm=landlock,lockdown,yama,integrity,apparmor,bpf.*"$')
        self.assertIn('GRUB_THEME="/usr/share/grub/themes/garuda-dr460nized/theme.txt"', text)

    def test_missing_theme_and_kernel_are_reported_not_fatal(self):
        self.env['GRUB_THEME_ROOT'] = str(self.tmp / 'empty')
        result = self.run_script()
        self.assertIn('Theme file missing', result.stderr)
        self.assertIn('GRUB_TOP_LEVEL', result.stderr)
        self.assertEqual(self.grub.read_text(), SOURCE.read_text())


if __name__ == '__main__':
    unittest.main()
