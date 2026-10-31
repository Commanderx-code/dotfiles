import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
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

    def backup_mocks(self, restic='exit 0'):
        mock = self.root / 'bin'
        mock.mkdir(exist_ok=True)
        for name, body in {'mountpoint': 'exit 0', 'restic': restic, 'kwallet-query': 'exit 0'}.items():
            file = mock / name
            file.write_text('#!/bin/sh\n' + body + '\n')
            file.chmod(0o755)
        if str(mock) not in self.env['PATH']:
            self.env.update(PATH=str(mock) + os.pathsep + self.env['PATH'])
        self.env.update(XDG_RUNTIME_DIR=str(self.root), XDG_STATE_HOME=str(self.root / 'state'),
                        RESTIC_REPOSITORY=str(self.root))
        self.env.pop('BACKUP_LOCK_HELD', None)

    def test_failed_backup_does_not_start_cooldown(self):
        self.backup_mocks(restic='exit 42')
        result = self.fish('backup-on-mount.fish')
        self.assertNotEqual(result.returncode, 0)
        stamp = self.root / 'backup-on-mount.stamp'
        self.assertFalse(stamp.exists())
        self.backup_mocks()
        result = self.fish('backup-on-mount.fish')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(stamp.exists())

    def test_manual_backup_waits_for_a_running_one(self):
        self.backup_mocks()
        lock = self.root / 'backup-personal.lock'
        # Stands in for the automatic run that starts when the drive mounts.
        holder = subprocess.Popen(['flock', str(lock), 'sh', '-c', 'sleep 1.5; date +%s.%N'],
                                  stdout=subprocess.PIPE, text=True)
        try:
            for _ in range(100):
                if lock.exists() and subprocess.run(['flock', '--nonblock', str(lock), 'true']).returncode:
                    break
                time.sleep(0.02)
            result = self.fish('backup-personal.fish')
            finished = time.time()
        finally:
            released = float(holder.communicate()[0])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('waiting for it to finish', result.stdout)
        self.assertIn('Personal backup complete.', result.stdout)
        self.assertGreaterEqual(finished, released)

    def test_backups_run_straight_away_when_nothing_else_is(self):
        self.backup_mocks()
        result = self.fish('backup-personal.fish')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('waiting', result.stdout)

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
            result = subprocess.run([FISH, '--no-config', '--interactive', '-c',
                'source $argv[1]; ' + alias + ' --color=never --icons=never $argv[2]',
                str(ROOT / 'configs/fish/conf.d/eza-shared.fish'), str(self.root)],
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

    def offsite_mocks(self, restic='exit 0'):
        mock = self.root / 'bin'
        mock.mkdir(exist_ok=True)
        wallet = 'case "$4" in *-key-id) echo KEYID;; *-key) echo SECRET;; *) exit 1;; esac'
        for name, body in {'restic': restic, 'kwallet-query': wallet, 'nm-online': 'exit 0'}.items():
            file = mock / name
            file.write_text('#!/bin/sh\n' + body + '\n')
            file.chmod(0o755)
        if str(mock) not in self.env['PATH']:
            self.env.update(PATH=str(mock) + os.pathsep + self.env['PATH'])
        self.env.update(XDG_RUNTIME_DIR=str(self.root), XDG_STATE_HOME=str(self.root / 'state'),
                        RESTIC_WALLET_FOLDER='folder', RESTIC_WALLET_ENTRY='local', RESTIC_WALLET='wallet',
                        OFFSITE_REPOSITORY='s3:https://s3.example.invalid/bucket/home',
                        OFFSITE_WALLET_ENTRY='B2')
        self.env.pop('OFFSITE_LOCK_HELD', None)

    def test_offsite_backup_is_a_no_op_until_configured(self):
        self.offsite_mocks()
        self.env.pop('OFFSITE_REPOSITORY')
        result = self.fish('backup-offsite.fish')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('not configured', result.stdout)
        self.assertFalse(list(self.root.rglob('backup.success')))

    def test_offsite_backup_records_success_only_after_restic_succeeds(self):
        self.offsite_mocks(restic='printf "%s\\n" "$@" > "$RESTIC_ARGS_FILE"; exit 42')
        self.env['RESTIC_ARGS_FILE'] = str(self.root / 'restic-args')
        result = self.fish('backup-offsite.fish')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(list(self.root.rglob('backup.success')))
        arguments = (self.root / 'restic-args').read_text().splitlines()
        self.assertIn(self.env['OFFSITE_REPOSITORY'], arguments)
        self.assertIn('--exclude-caches', arguments)
        self.assertIn('--exclude-larger-than', arguments)
        self.assertIn(str(Path.home() / 'Downloads'), arguments)
        self.offsite_mocks()
        result = self.fish('backup-offsite.fish')
        self.assertEqual(result.returncode, 0, result.stderr)
        stamps = list(self.root.rglob('backup.success'))
        self.assertEqual(len(stamps), 1)
        import hashlib
        self.assertEqual(stamps[0].parent.name, hashlib.sha256(self.env['OFFSITE_REPOSITORY'].encode()).hexdigest())

    def test_offsite_backup_stops_without_wallet_credentials(self):
        self.offsite_mocks()
        (self.root / 'bin/kwallet-query').write_text('#!/bin/sh\nexit 1\n')
        result = self.fish('backup-offsite.fish')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('backup-offsite --setup', result.stdout)
        self.assertFalse(list(self.root.rglob('backup.success')))

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
