"""restore-grub installs the theme and edits the boot settings without touching the system."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'home-manager/scripts/restore-grub.sh'


class RestoreGrubTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='restore-grub-'))
        self.addCleanup(shutil.rmtree, self.tmp)
        binaries = self.tmp / 'bin'
        binaries.mkdir()
        # sudo runs its command as this user; update-grub records that it was called.
        (binaries / 'sudo').write_text('#!/bin/sh\nexec "$@"\n')
        (binaries / 'update-grub').write_text('#!/bin/sh\necho called >> "$GRUB_UPDATE_LOG"\n')
        for path in binaries.iterdir():
            path.chmod(0o755)
        self.grub = self.tmp / 'grub'
        self.theme = self.tmp / 'themes/cachyos'
        self.log = self.tmp / 'update.log'
        self.env = dict(os.environ, PATH=f'{binaries}:{os.environ["PATH"]}', DOTFILES_DIR=str(ROOT),
                        GRUB_THEME_DIR=str(self.theme), GRUB_DEFAULT_FILE=str(self.grub), GRUB_UPDATE_LOG=str(self.log))

    def run_script(self):
        return subprocess.run(['bash', str(SCRIPT)], env=self.env, capture_output=True, text=True, check=True)

    def test_theme_and_settings_are_installed_once(self):
        self.grub.write_text('GRUB_DEFAULT=0\nGRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 splash quiet"\n#GRUB_THEME=\nGRUB_GFXMODE=auto\n')
        self.run_script()
        self.assertTrue((self.theme / 'theme.txt').is_file())
        self.assertTrue((self.theme / 'icons/arch.png').is_file())
        text = self.grub.read_text()
        self.assertIn(f'GRUB_THEME="{self.theme}/theme.txt"', text)
        self.assertIn('GRUB_GFXMODE=1920x1080', text)
        self.assertIn('GRUB_CMDLINE_LINUX_DEFAULT="lsm=landlock,lockdown,yama,integrity,apparmor,bpf loglevel=3 splash quiet"', text)
        self.assertEqual(text.count('GRUB_THEME='), 1)
        self.assertEqual(self.log.read_text(), 'called\n')
        # A second run changes nothing and says so.
        result = self.run_script()
        self.assertEqual(self.grub.read_text(), text)
        self.assertIn('already current', result.stdout)

    def test_the_machines_own_choices_stay(self):
        self.grub.write_text('GRUB_CMDLINE_LINUX_DEFAULT="lsm=landlock,yama quiet"\nGRUB_GFXMODE=2560x1440\n')
        self.run_script()
        text = self.grub.read_text()
        self.assertIn('GRUB_CMDLINE_LINUX_DEFAULT="lsm=landlock,yama quiet"', text)
        self.assertIn('GRUB_GFXMODE=2560x1440', text)
        self.assertIn('GRUB_THEME=', text)

    def test_a_missing_settings_file_is_created(self):
        self.run_script()
        text = self.grub.read_text()
        self.assertIn('lsm=landlock,lockdown,yama,integrity,apparmor,bpf', text)
        self.assertIn('GRUB_GFXMODE=1920x1080', text)


if __name__ == '__main__':
    unittest.main()
