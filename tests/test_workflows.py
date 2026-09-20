import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / 'home-manager/scripts'
FISH = shutil.which('fish')


class Workflows(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, DOTFILES_DIR=str(self.root),
                        DOTFILES_MACHINE_CONFIG=str(ROOT / 'home-manager/machine.json'))

    def fish(self, script, *args):
        return subprocess.run([FISH, '--no-config', str(SCRIPTS / script), *args],
                              env=self.env, capture_output=True, text=True)

    def test_restore_previews_do_not_write_or_run_system_commands(self):
        inventories = self.root / 'system-backup/inventories'
        inventories.mkdir(parents=True)
        marker = inventories / 'pacman-native-explicit.txt'
        marker.write_text('example\n')
        before = sorted(p.relative_to(self.root) for p in self.root.rglob('*'))
        for script in ('restore-system.fish', 'restore-apps.fish'):
            result = self.fish(script, '--dry-run')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(self.root), result.stdout)
            self.assertIn('Missing:', result.stdout)
        self.assertEqual(before, sorted(p.relative_to(self.root) for p in self.root.rglob('*')))
        self.assertEqual(marker.read_text(), 'example\n')

    def test_restore_preview_rejects_missing_snapshot(self):
        for script in ('restore-system.fish', 'restore-apps.fish'):
            result = self.fish(script, '--dry-run')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('not found', result.stderr)

    def test_settings_preserve_overrides_and_spaces(self):
        self.env['BACKUP_MOUNT'] = str(self.root / 'drive with spaces')
        result = subprocess.run([FISH, '--no-config', '-c',
            'source $argv[1]; or exit 1; printf "%s\\n" "$DOTFILES_DIR" "$BACKUP_MOUNT"',
            str(SCRIPTS / 'lib/settings.fish')], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [str(self.root), self.env['BACKUP_MOUNT']])

    def test_failed_inventory_does_not_claim_completion(self):
        mock = self.root / 'bin'
        mock.mkdir()
        pacman = mock / 'pacman'
        pacman.write_text('#!/bin/sh\nexit 42\n')
        pacman.chmod(0o755)
        self.env['PATH'] = str(mock) + os.pathsep + self.env['PATH']
        result = self.fish('backup-app-inventory.fish')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'system-backup').exists())
        staged = next(self.root.glob('.system-backup-capture-*'))
        metadata = json.loads((staged / 'inventories/applications-metadata.json').read_text())
        self.assertEqual(metadata['status'], 'started')
        self.assertNotIn('completed_at', metadata)
        self.assertNotIn('backup complete', result.stdout)

    def test_failed_backup_does_not_start_cooldown(self):
        mock = self.root / 'bin'
        mock.mkdir()
        for name, body in {'mountpoint': 'exit 0', 'flock': 'exit 42',
                           'restic': 'exit 0', 'kwallet-query': 'exit 0'}.items():
            file = mock / name
            file.write_text('#!/bin/sh\n' + body + '\n')
            file.chmod(0o755)
        self.env.update(PATH=str(mock) + os.pathsep + self.env['PATH'],
                        XDG_RUNTIME_DIR=str(self.root), XDG_STATE_HOME=str(self.root / 'state'),
                        RESTIC_REPOSITORY=str(self.root))
        result = self.fish('backup-on-mount.fish')
        self.assertNotEqual(result.returncode, 0)
        stamp = self.root / 'backup-on-mount.stamp'
        self.assertFalse(stamp.exists())
        (mock / 'flock').write_text('#!/bin/sh\nexit 0\n')
        result = self.fish('backup-on-mount.fish')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(stamp.exists())

    def test_pre_restore_copy_failure_aborts(self):
        # Exercise the actual helper with a failing privileged copy, never sudo.
        source = (SCRIPTS / 'restore-system.fish').read_text()
        helper = source.split('function backup_if_exists\n', 1)[1].split('\nend\n', 1)[0]
        mock = self.root / 'bin'
        mock.mkdir()
        sudo = mock / 'sudo'
        sudo.write_text('#!/bin/sh\nexit 42\n')
        sudo.chmod(0o755)
        self.env['PATH'] = str(mock) + os.pathsep + self.env['PATH']
        code = ('function fail; echo "ERROR: $argv"; exit 1; end\n'
                'function backup_if_exists\n' + helper + '\nend\n'
                'backup_if_exists /etc/os-release $argv[1]\n'
                'echo RESTORE_CONTINUED\n')
        result = subprocess.run([FISH, '--no-config', '-c', code, str(self.root / 'saved')],
                                env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Could not preserve', result.stdout)
        self.assertNotIn('RESTORE_CONTINUED', result.stdout)

    def test_eza_aliases_filter_entries(self):
        (self.root / 'directory').mkdir()
        (self.root / 'file').touch()
        for alias, expected, absent in [('ldir', 'directory', 'file'), ('lf', 'file', 'directory')]:
            result = subprocess.run([FISH, '--no-config', '-c',
                'source $argv[1]; ' + alias + ' --color=never --icons=never $argv[2]',
                str(ROOT / 'configs/fish/conf.d/eza.fish'), str(self.root)],
                env=self.env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(expected, result.stdout)
            self.assertNotIn(absent, result.stdout)

    def test_snapshot_removes_missing_system_sources(self):
        source = (SCRIPTS / 'backup-system-state.fish').read_text()
        blocks = re.findall(r'if test -([fd]) (/[^\n]+)\n(.*?)\nend', source, re.S)
        self.assertEqual(len(blocks), 9)
        backup = self.root / 'snapshot'
        for kind, original, body in blocks:
            with self.subTest(source=original):
                fixture = self.root / 'sources' / original.lstrip('/')
                fixture.parent.mkdir(parents=True, exist_ok=True)
                if kind == 'd':
                    fixture.mkdir()
                    (fixture / 'content').write_text('current')
                else:
                    fixture.write_text('current')
                target = re.search(r'else\n    sudo rm -rf -- "\$BACKUP/([^"\n]+)"', body)[1]
                destination = backup / target
                destination.parent.mkdir(parents=True, exist_ok=True)
                block = ('if test -' + kind + ' "' + str(fixture) + '"\n' +
                         body.replace(original, '"' + str(fixture) + '"') + '\nend')
                code = 'function sudo; command $argv; end; set -l BACKUP $argv[1]\n' + block
                def capture():
                    return subprocess.run([FISH, '--no-config', '-c', code, str(backup)],
                                          env=self.env, capture_output=True, text=True)
                result = capture()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(destination.exists())
                shutil.rmtree(fixture) if kind == 'd' else fixture.unlink()
                result = capture()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(destination.exists())

    def test_personal_backup_passes_wallet_command_and_records_success(self):
        mock = self.root / 'bin'
        mock.mkdir()
        restic = mock / 'restic'
        restic.write_text("#!/usr/bin/env python3\nimport shlex,sys\n"
                         "args=sys.argv[1:]\n"
                         "command=shlex.split(args[args.index('--password-command')+1])\n"
                         "assert command == ['kwallet-query','-f','folder with spaces','-r','entry','wallet'], command\n"
                         "import os\nif 'backup' in args: assert os.environ['TEST_EXTRA_BACKUP'] in args, args\n")
        restic.chmod(0o755)
        wallet = mock / 'kwallet-query'
        wallet.write_text('#!/bin/sh\nexit 0\n')
        wallet.chmod(0o755)
        extra = self.root / 'external repository'
        extra.mkdir()
        registration = self.root / 'config/backup-personal/paths.d/example-app'
        registration.parent.mkdir(parents=True)
        registration.write_text('# Registered by an independent application\n' + str(extra) + '\n')
        self.env.update(XDG_CONFIG_HOME=str(self.root / 'config'), TEST_EXTRA_BACKUP=str(extra))
        self.env.update(PATH=str(mock) + os.pathsep + self.env['PATH'],
                        RESTIC_REPOSITORY=str(self.root), XDG_STATE_HOME=str(self.root / 'state'),
                        RESTIC_WALLET_FOLDER='folder with spaces', RESTIC_WALLET_ENTRY='entry',
                        RESTIC_WALLET='wallet')
        result = self.fish('backup-personal.fish')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(list(self.root.rglob('backup.success'))), 1)

    def test_metadata_tracks_separate_capture_times(self):
        for kind in ('system', 'applications'):
            for status in ('started', 'completed'):
                subprocess.run(['python3', str(SCRIPTS / 'snapshot-metadata.py'),
                                str(self.root), kind, status], env=self.env, check=True)
            data = json.loads((self.root / f'{kind}-metadata.json').read_text())
            self.assertEqual(data['status'], 'completed')
            self.assertLessEqual(data['started_at'], data['completed_at'])
            self.assertTrue(data['hostname'])
            self.assertIn('kernel', data)
        self.assertEqual(len(list(self.root.glob('*-metadata.json'))), 2)


if __name__ == '__main__':
    unittest.main()
