"""restore-limine installs the boot menu look and kernel parameters without touching the system."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'home-manager/scripts/restore-limine.sh'
spec = importlib.util.spec_from_file_location('limine_config', ROOT / 'home-manager/scripts/limine-config.py')
limine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(limine)
FRAGMENT = (ROOT / 'limine/themes/cachyos/limine.conf').read_text()
GARUDA = (ROOT / 'limine/themes/garuda/limine.conf').read_text()
MACHINE = '''# Limine boot loader configuration
timeout: 5
remember_last_entry: yes
wallpaper: boot():/limine-splash.png
wallpaper: boot():/other.png

/+CachyOS
    comment: machine-id=abc
    //linux-cachyos
        protocol: linux
        cmdline: quiet splash
        path: boot():/abc/linux-cachyos/vmlinuz-linux-cachyos
'''


class RenderTests(unittest.TestCase):
    def test_appearance_replaces_keys_and_keeps_entries_and_is_repeatable(self):
        merged = limine.merge_appearance(MACHINE, FRAGMENT)
        head, _, entries = merged.partition('/+CachyOS')
        self.assertEqual(head.count('timeout:'), 1)
        self.assertIn('timeout: 2', head)
        self.assertEqual(head.count('wallpaper:'), 1)
        self.assertIn('wallpaper: boot():/dotfiles-splash.png', head)
        self.assertIn('remember_last_entry: yes', head)
        self.assertIn('# Limine boot loader configuration', head)
        self.assertIn('term_palette: 1e1e2e;', head)
        self.assertNotIn('#', head.split(limine.MARKER)[1])
        self.assertEqual('/+CachyOS' + entries, MACHINE[MACHINE.index('/+CachyOS'):])
        self.assertEqual(limine.merge_appearance(merged, FRAGMENT), merged)
        self.assertTrue(limine.merge_appearance('', FRAGMENT).startswith(limine.MARKER))
        with self.assertRaises(ValueError):
            limine.merge_appearance(MACHINE, 'rm -rf /\n')

    def test_cmdline_set_replaces_the_parameter_with_the_same_name(self):
        original = 'ESP_PATH="/boot"\nKERNEL_CMDLINE[default]="quiet splash lsm=landlock,yama"\nBOOT_ORDER="*, Snapshots"\n'
        rendered = limine.render_cmdline(original, 'set', ['lsm=landlock,lockdown,yama,integrity,apparmor,bpf'])
        self.assertEqual(rendered, 'ESP_PATH="/boot"\nKERNEL_CMDLINE[default]="quiet splash lsm=landlock,lockdown,yama,integrity,apparmor,bpf"\nBOOT_ORDER="*, Snapshots"\n')
        self.assertEqual(limine.render_cmdline(rendered, 'set', ['lsm=landlock,lockdown,yama,integrity,apparmor,bpf']), rendered)
        self.assertEqual(limine.render_cmdline('KERNEL_CMDLINE[default]+=" quiet"\n', 'add', ['splash']),
                         'KERNEL_CMDLINE[default]+="quiet splash"\n')
        self.assertEqual(limine.render_cmdline('KERNEL_CMDLINE["default"]="quiet splash rhgb"\n', 'remove', ['splash', 'rhgb']),
                         'KERNEL_CMDLINE["default"]="quiet"\n')
        with self.assertRaises(ValueError):
            limine.render_cmdline('BOOT_ORDER="*"\n', 'set', ['lsm=apparmor'])
        with self.assertRaises(ValueError):
            limine.render_cmdline('KERNEL_CMDLINE[default]="quiet\n', 'set', ['lsm=apparmor'])


class RestoreLimineTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='restore-limine-'))
        self.addCleanup(shutil.rmtree, self.tmp)
        binaries = self.tmp / 'bin'
        binaries.mkdir()
        # sudo runs its command as this user; the entry tool records that it ran.
        (binaries / 'sudo').write_text('#!/bin/sh\nexec "$@"\n')
        (binaries / 'limine-mkinitcpio').write_text('#!/bin/sh\necho regenerated >> "$LIMINE_LOG"\n')
        for path in binaries.iterdir():
            path.chmod(0o755)
        self.boot = self.tmp / 'boot'
        self.boot.mkdir()
        self.conf = self.boot / 'limine.conf'
        self.conf.write_text(MACHINE)
        self.default = self.tmp / 'etc/default/limine'
        self.default.parent.mkdir(parents=True)
        self.default.write_text('ESP_PATH="/boot"\nKERNEL_CMDLINE[default]="quiet splash"\n')
        self.log = self.tmp / 'calls.log'
        self.env = dict(os.environ, PATH=f'{binaries}:{os.environ["PATH"]}', DOTFILES_DIR=str(ROOT),
                        LIMINE_CONF=str(self.conf), LIMINE_DEFAULT_FILE=str(self.default), LIMINE_LOG=str(self.log),
                        XDG_CONFIG_HOME=str(self.tmp / 'config'))

    def run_script(self, *args):
        return subprocess.run(['bash', str(SCRIPT), *args], env=self.env, capture_output=True, text=True, check=True)

    def test_menu_wallpaper_and_parameters_are_installed_with_backups_once(self):
        result = self.run_script()
        self.assertEqual((self.boot / 'dotfiles-splash.png').read_bytes(), (ROOT / 'limine/themes/cachyos/splash.png').read_bytes())
        self.assertIn('Boot menu look: cachyos', result.stdout)
        self.assertEqual(self.conf.read_text(), limine.merge_appearance(MACHINE, FRAGMENT))
        self.assertEqual(self.conf.with_name('limine.conf.before-dotfiles').read_text(), MACHINE)
        self.assertIn('lsm=landlock,lockdown,yama,integrity,apparmor,bpf', self.default.read_text())
        self.assertIn('quiet splash', self.default.read_text())
        self.assertEqual(self.default.with_name('limine.before-dotfiles').read_text(), 'ESP_PATH="/boot"\nKERNEL_CMDLINE[default]="quiet splash"\n')
        self.assertEqual(self.log.read_text(), 'regenerated\n')
        self.assertEqual(result.stderr, '')
        # A second run changes nothing, keeps the first backups and says so.
        result = self.run_script()
        self.assertIn('already current', result.stdout)
        self.assertEqual(self.log.read_text(), 'regenerated\n')
        self.assertEqual(self.conf.with_name('limine.conf.before-dotfiles').read_text(), MACHINE)

    def test_the_garuda_look_and_the_remembered_choice(self):
        result = self.run_script('garuda', '--menu-only')
        self.assertEqual(self.conf.read_text(), limine.merge_appearance(MACHINE, GARUDA))
        self.assertIn('term_foreground_bright: 02ccfc', self.conf.read_text())
        self.assertEqual((self.boot / 'dotfiles-splash.png').read_bytes(), (ROOT / 'limine/themes/garuda/splash.png').read_bytes())
        self.assertIn('Boot menu look: garuda', result.stdout)
        (self.tmp / 'config/dotfiles').mkdir(parents=True)
        (self.tmp / 'config/dotfiles/boot-theme').write_text('garuda\n')
        self.assertIn('already current', self.run_script('--menu-only').stdout)
        with self.assertRaises(subprocess.CalledProcessError):
            self.run_script('neon')

    def test_menu_only_leaves_the_kernel_parameters_alone(self):
        self.run_script('--menu-only')
        self.assertIn('timeout: 2', self.conf.read_text())
        self.assertEqual(self.default.read_text(), 'ESP_PATH="/boot"\nKERNEL_CMDLINE[default]="quiet splash"\n')
        self.assertFalse(self.log.exists())

    def test_missing_cmdline_line_or_defaults_file_is_reported_not_fatal(self):
        self.default.write_text('ESP_PATH="/boot"\n')
        result = self.run_script()
        self.assertIn('KERNEL_CMDLINE[default]', result.stderr)
        self.assertEqual(self.default.read_text(), 'ESP_PATH="/boot"\n')
        self.default.unlink()
        result = self.run_script()
        self.assertIn('by hand', result.stderr)
        self.assertIn('lsm=landlock', result.stderr)
        self.assertFalse(self.log.exists())


if __name__ == '__main__':
    unittest.main()
