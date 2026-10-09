"""Palette files, the shared prompt's palette, and the rice command."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
THEMES = ROOT / 'configs/themes'
HEX = re.compile(r'^#[0-9a-f]{6}$')
COLORS = ('base', 'mantle', 'surface', 'overlay', 'muted', 'subtext', 'text',
          'red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'purple', 'pink')


def themes():
    return {path.stem: json.loads(path.read_text()) for path in sorted(THEMES.glob('*.json'))}


class PaletteTests(unittest.TestCase):
    def test_every_palette_is_complete(self):
        colorschemes = (ROOT / 'configs/nvim/lua/plugins/colorscheme.lua').read_text()
        self.assertIn('eldritch', themes())
        for name, theme in themes().items():
            with self.subTest(theme=name):
                self.assertRegex(name, r'^[a-z0-9][a-z0-9-]*$')
                self.assertEqual(tuple(theme['colors']), COLORS)
                terminal = theme['terminal']
                self.assertEqual(len(terminal['ansi']), 16)
                values = [*theme['colors'].values(), *terminal['ansi'], *theme['diff'].values(),
                          terminal['cursor'], terminal['cursorText'], terminal['selection'], terminal['selectionText']]
                for value in values:
                    self.assertRegex(value, HEX)
                apps = theme['apps']
                # The Neovim colorscheme's plugin is installed (lazy-loaded) in colorscheme.lua.
                self.assertIn(apps['nvim'].split('-')[0], colorschemes)
                self.assertNotIn('sddm', apps)
                self.assertTrue(apps['bat'])
                self.assertIn('theme', apps['zed'])

    def test_selection_names_a_palette(self):
        selection = json.loads((ROOT / 'home-manager/rice.json').read_text())
        self.assertIn(selection['theme'], themes())
        # The optional Neovim override is a colorscheme name: the <leader>th picker
        # writes it, and it may be a built-in as well as a plugin's.
        if 'nvim' in selection:
            self.assertRegex(selection['nvim'], r'^[A-Za-z0-9_-]+$')

    def test_shared_prompt_palette_matches_the_eldritch_file(self):
        prompt = tomllib.loads((ROOT / 'configs/starship/starship.toml').read_text())
        roles = dict(re.findall(r'^\s*(\w+) = c\.(\w+);', (ROOT / 'home-manager/modules/starship.nix').read_text(), re.M))
        eldritch = themes()['eldritch']['colors']
        self.assertEqual(prompt['palette'], 'eldritch')
        self.assertEqual(prompt['palettes']['eldritch'], {role: eldritch[key] for role, key in roles.items()})
        # Every colour the layout names is a palette entry, so a swapped palette covers it.
        styles = ' '.join(re.findall(r'(?:bg|fg):(\w+)', (ROOT / 'configs/starship/starship.toml').read_text()))
        self.assertLessEqual(set(styles.split()), set(roles))


class RiceCommandTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='dotfiles-rice-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.repo = self.root / 'dotfiles'
        for name in ('configs/themes', 'configs/zed', 'sddm', 'home-manager/scripts'):
            shutil.copytree(ROOT / name, self.repo / name)
        for name in ('home-manager/rice.json', 'home-manager/machine.json'):
            shutil.copy(ROOT / name, self.repo / name)
        self.log = self.root / 'log'
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        for name, body in (('rebuild', 'echo rebuild >> "$LOG"; exit "${FAIL:-0}"'),
                           ('sudo', 'echo sudo "$1" >> "$LOG"; exit 1')):
            script = bin_dir / name
            script.write_text(f'#!/bin/sh\n{body}\n')
            script.chmod(0o755)
        self.env = dict(os.environ, DOTFILES_DIR=str(self.repo), LOG=str(self.log),
                        DOTFILES_MACHINE_CONFIG=str(self.repo / 'home-manager/machine.json'),
                        RICE_REBUILD=str(bin_dir / 'rebuild'), XDG_CONFIG_HOME=str(self.root / 'config'),
                        PATH=str(bin_dir) + os.pathsep + os.environ['PATH'])
        self.env.pop('XDG_CURRENT_DESKTOP', None)

    def rice(self, *args, **env):
        return subprocess.run([shutil.which('fish'), '--no-config', str(self.repo / 'home-manager/scripts/rice.fish'), *args],
                              env=dict(self.env, **env), text=True, capture_output=True)

    def selection(self):
        return json.loads((self.repo / 'home-manager/rice.json').read_text())['theme']

    def test_switch_writes_choice_and_zed_but_never_the_login_screen(self):
        metadata = (self.repo / 'sddm/metadata.desktop').read_bytes()
        result = self.rice('catppuccin-mocha')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.selection(), 'catppuccin-mocha')
        zed = json.loads((self.repo / 'configs/zed/settings.json').read_text())
        self.assertEqual(zed['theme']['dark'], 'Catppuccin Mocha')
        self.assertTrue(zed['auto_install_extensions']['catppuccin'])
        # The SDDM selection is untouched and sudo is never called.
        self.assertEqual((self.repo / 'sddm/metadata.desktop').read_bytes(), metadata)
        self.assertEqual(self.log.read_text().splitlines(), ['rebuild'])

    def test_neovim_override_survives_a_palette_switch_and_is_listed(self):
        selection = self.repo / 'home-manager/rice.json'
        selection.write_text(json.dumps({'theme': 'eldritch', 'nvim': 'tokyonight-storm'}))
        self.assertEqual(self.rice('nord').returncode, 0)
        self.assertEqual(json.loads(selection.read_text()), {'theme': 'nord', 'nvim': 'tokyonight-storm'})
        self.assertIn('Neovim colorscheme: tokyonight-storm', self.rice().stdout)

    def test_failed_rebuild_restores_the_previous_choice(self):
        zed = (self.repo / 'configs/zed/settings.json').read_text()
        before = self.selection()
        result = self.rice('nord', FAIL='1')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.selection(), before)
        self.assertEqual((self.repo / 'configs/zed/settings.json').read_text(), zed)

    def test_unknown_or_unsafe_names_change_nothing(self):
        for name in ('missing', '../eldritch', '-x'):
            with self.subTest(name=name):
                self.assertNotEqual(self.rice(name).returncode, 0)
                self.assertEqual(self.selection(), 'eldritch')
        self.assertFalse(self.log.exists())

    def test_no_rebuild_and_listing(self):
        result = self.rice('tokyonight-storm', '--no-rebuild')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())
        listing = self.rice()
        self.assertIn('* tokyonight-storm', listing.stdout)
        self.assertIn('Eldritch', self.rice('show', 'eldritch').stdout)


if __name__ == '__main__':
    unittest.main()
