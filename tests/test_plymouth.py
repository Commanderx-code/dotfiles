"""restore-plymouth selects the boot splash and rebuilds the boot images without touching the system."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'home-manager/scripts/restore-plymouth.sh'
SOURCE = ROOT / 'plymouth/theme'
BASH = shutil.which('bash')


class RestorePlymouthTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='restore-plymouth-'))
        self.addCleanup(shutil.rmtree, self.tmp)
        self.binaries = self.tmp / 'bin'
        self.binaries.mkdir()
        self.state = self.tmp / 'current-theme'
        self.state.write_text('bgrt\n')
        self.log = self.tmp / 'calls.log'
        # sudo runs its command as this user; plymouth-set-default-theme keeps the
        # chosen theme in a file; pacman knows no theme packages; the rebuild tools
        # record that they were called.
        (self.binaries / 'sudo').write_text('#!/bin/sh\nexec "$@"\n')
        (self.binaries / 'plymouth-set-default-theme').write_text(
            '#!/bin/sh\nif [ $# -eq 0 ]; then cat "$PLYMOUTH_STATE"; else echo "$1" > "$PLYMOUTH_STATE"; fi\n')
        (self.binaries / 'pacman').write_text('#!/bin/sh\nexit 1\n')
        for tool in ('dracut-rebuild', 'mkinitcpio', 'dracut'):
            (self.binaries / tool).write_text(f'#!/bin/sh\necho "{tool} $*" >> "$PLYMOUTH_LOG"\n')
        for path in self.binaries.iterdir():
            path.chmod(0o755)
        # Only the fakes and the few utilities the script needs are on PATH, so the
        # machine's own rebuild tools cannot be picked up when a fake is removed.
        utilities = self.tmp / 'utilities'
        utilities.mkdir()
        for name in ('dirname', 'head', 'tr', 'cp', 'cat'):
            (utilities / name).symlink_to(shutil.which(name))
        self.themes = self.tmp / 'themes'
        self.add_theme(SOURCE.read_text().strip())
        self.env = dict(os.environ, PATH=f'{self.binaries}:{utilities}', DOTFILES_DIR=str(ROOT),
                        PLYMOUTH_THEMES_DIR=str(self.themes), PLYMOUTH_STATE=str(self.state), PLYMOUTH_LOG=str(self.log))

    def add_theme(self, name, root=None):
        directory = (root or self.themes) / name
        directory.mkdir(parents=True)
        (directory / f'{name}.plymouth').write_text('[Plymouth Theme]\n')

    def run_script(self, *args, check=True):
        return subprocess.run([BASH, str(SCRIPT), *args], env=self.env, capture_output=True, text=True, check=check)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_the_repository_theme_is_selected_and_the_boot_images_rebuilt(self):
        result = self.run_script()
        self.assertEqual(self.state.read_text().strip(), SOURCE.read_text().strip())
        self.assertEqual(self.calls(), ['dracut-rebuild '])
        self.assertEqual(result.stderr, '')
        # A second run changes nothing and does not rebuild.
        result = self.run_script()
        self.assertIn('already current', result.stdout)
        self.assertEqual(self.calls(), ['dracut-rebuild '])

    def test_rebuild_keeps_the_current_theme(self):
        self.state.write_text('spinner\n')
        result = self.run_script('--rebuild')
        self.assertEqual(self.state.read_text().strip(), 'spinner')
        self.assertEqual(self.calls(), ['dracut-rebuild '])
        self.assertIn('spinner', result.stdout)
        result = self.run_script('--rebuild', 'spinner', check=False)
        self.assertEqual(result.returncode, 2)

    def test_a_named_theme_wins_over_the_repository(self):
        self.add_theme('spinner')
        self.run_script('spinner')
        self.assertEqual(self.state.read_text().strip(), 'spinner')

    def test_a_missing_theme_is_explained_and_nothing_changes(self):
        shutil.rmtree(self.themes)
        result = self.run_script(check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn('Get New', result.stderr)
        self.assertEqual(self.state.read_text().strip(), 'bgrt')
        self.assertEqual(self.calls(), [])

    def test_a_theme_kept_in_the_repository_is_installed(self):
        dotfiles = self.tmp / 'dotfiles'
        (dotfiles / 'plymouth').mkdir(parents=True)
        (dotfiles / 'plymouth/theme').write_text('kept\n')
        self.add_theme('kept', dotfiles / 'plymouth/themes')
        self.env['DOTFILES_DIR'] = str(dotfiles)
        self.run_script()
        self.assertTrue((self.themes / 'kept/kept.plymouth').is_file())
        self.assertEqual(self.state.read_text().strip(), 'kept')

    def test_the_initramfs_tool_is_chosen_in_order(self):
        (self.binaries / 'dracut-rebuild').unlink()
        self.run_script()
        self.assertEqual(self.calls(), ['mkinitcpio -P'])
        (self.binaries / 'mkinitcpio').unlink()
        self.run_script('--rebuild')
        self.assertEqual(self.calls()[-1], 'dracut --force --regenerate-all')

    def test_odd_theme_names_are_refused(self):
        result = self.run_script('../etc', check=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.state.read_text().strip(), 'bgrt')


if __name__ == '__main__':
    unittest.main()
