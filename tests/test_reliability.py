import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'home-manager/scripts' / (name + '.py'))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


transaction = module('snapshot-transaction')
restic_job = module('restic-job')


class Reliability(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-reliability-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_snapshot_success_failure_and_previous_generation(self):
        destination = self.root / 'system-backup'
        destination.mkdir()
        (destination / 'version').write_text('original')
        (destination / 'unmanaged').write_text('preserve me')
        capture = self.root / 'capture.py'
        capture.write_text('''import json, pathlib, sys
stage = pathlib.Path(sys.argv[-1])
(stage / 'version').write_text(sys.argv[1])
(stage / 'inventories').mkdir(exist_ok=True)
(stage / 'inventories/system-metadata.json').write_text(json.dumps({'kind': 'system', 'status': 'completed'}))
sys.exit(int(sys.argv[2]))
''')
        def run(version, status=0):
            return transaction.capture(destination, [sys.executable, str(capture), version, str(status)], 'system')
        self.assertEqual(run('failed', 1), 1)
        self.assertEqual((destination / 'version').read_text(), 'original')
        self.assertEqual(run('second'), 0)
        previous = self.root / '.system-backup.previous'
        self.assertEqual((previous / 'version').read_text(), 'original')
        self.assertEqual((destination / 'version').read_text(), 'second')
        self.assertEqual(run('third'), 0)
        self.assertEqual((previous / 'version').read_text(), 'second')
        self.assertEqual((destination / 'unmanaged').read_text(), 'preserve me')
        with patch.object(transaction, 'exchange', side_effect=OSError('unsupported filesystem')):
            self.assertEqual(run('unpublished'), 1)
        self.assertEqual((destination / 'version').read_text(), 'third')

    def test_snapshot_rejects_missing_completion_record(self):
        destination = self.root / 'system-backup'
        metadata = destination / 'inventories/system-metadata.json'
        metadata.parent.mkdir(parents=True)
        metadata.write_text(json.dumps({'kind': 'system', 'status': 'completed'}))
        self.assertEqual(transaction.capture(destination, [sys.executable, '-c', 'pass'], 'system'), 1)
        self.assertTrue(metadata.exists())

    def test_restic_due_dates_only_advance_after_full_success(self):
        env = dict(RESTIC_REPOSITORY=str(self.root), BACKUP_MOUNT=str(self.root),
                   XDG_STATE_HOME=str(self.root / 'state'), RESTIC_WALLET='wallet',
                   RESTIC_WALLET_FOLDER='folder with spaces', RESTIC_WALLET_ENTRY='entry')
        calls = []
        mounted, check_status = True, 0
        def run(command):
            calls.append(command)
            status = (0 if mounted else 1) if command[0] == 'mountpoint' else (check_status if 'check' in command else 0)
            return subprocess.CompletedProcess(command, status)
        with patch.dict(os.environ, env), patch.object(restic_job.subprocess, 'run', side_effect=run), \
             patch.object(restic_job.shutil, 'which', return_value='/mock/tool'):
            mounted = False
            self.assertEqual(restic_job.run_job('maintenance', True), 0)
            self.assertFalse(list(self.root.rglob('*.success')))
            mounted, check_status = True, 1
            self.assertEqual(restic_job.run_job('maintenance', True), 1)
            self.assertFalse(list(self.root.rglob('*.success')))
            check_status = 0
            self.assertEqual(restic_job.run_job('maintenance', True), 0)
            stamp = next(self.root.rglob('maintenance.success'))
            old = stamp.stat().st_mtime_ns
            calls.clear()
            self.assertEqual(restic_job.run_job('maintenance', True), 0)
            self.assertFalse(any(c[0] == 'restic' for c in calls))
            self.assertEqual(stamp.stat().st_mtime_ns, old)
            stale = time.time() - 8 * 86400
            os.utime(stamp, (stale, stale))
            calls.clear()
            self.assertEqual(restic_job.run_job('maintenance', True), 0)
            self.assertEqual(sum(c[0] == 'restic' for c in calls), 2)
            self.assertEqual(restic_job.run_job('deep-check', True), 0)
            self.assertEqual(len(list(self.root.rglob('*.success'))), 2)

    def test_cleanup_and_gcom_failures(self):
        mock = self.root / 'bin'
        mock.mkdir()
        log = self.root / 'commands'
        env = dict(os.environ, PATH=str(mock) + os.pathsep + os.environ['PATH'], TEST_LOG=str(log))
        # All commands are fixtures: no package operations or repository writes.
        for name in ['sudo', 'git', 'paccache', 'flatpak', 'journalctl', 'pacman']:
            file = mock / name
            file.write_text('#!/bin/sh\nprintf "%s\\n" "$0 $*" >> "$TEST_LOG"\nexit 1\n')
            file.chmod(0o755)
        def fish(function, *args):
            return subprocess.run([shutil.which('fish'), '--no-config', '-c',
                'source $argv[1]; ' + function + ' $argv[2..]',
                str(ROOT / 'configs/fish/functions' / (function + '.fish')), *args],
                env=env, text=True, capture_output=True)
        result = fish('gcom')
        self.assertEqual(result.returncode, 1)
        self.assertFalse(log.exists())
        result = fish('gcom', 'message')
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('commit', log.read_text())
        result = fish('cleanup')
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('✅ Cleanup complete', result.stdout)
        self.assertEqual(log.read_text().count('paccache -rk3'), 1)
