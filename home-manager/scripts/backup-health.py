#!/usr/bin/env python3
"""Report locally recorded backup health without opening KWallet or Restic."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

JOBS = {'backup': 86400, 'maintenance': 7 * 86400, 'deep-check': 30 * 86400}
UNITS = ['backup-on-mount.service', 'restic-maintenance.service', 'restic-deep-check.service']


def completion(stamp, interval, now):
    if not stamp.exists():
        return {'status': 'unknown', 'completed_at': None}
    timestamp = stamp.stat().st_mtime
    age = now - timestamp
    return {'status': 'current' if 0 <= age < interval else 'overdue',
            'completed_at': datetime.datetime.fromtimestamp(timestamp, datetime.timezone.utc).isoformat(),
            'age_days': round(age / 86400, 2)}


def collect(env=os.environ):
    repo = Path(env['RESTIC_REPOSITORY'])
    root = Path(env['DOTFILES_DIR'])
    state_home = Path(env.get('XDG_STATE_HOME') or str(Path.home() / '.local/state'))
    identity = hashlib.sha256(os.fsencode(str(repo.resolve()))).hexdigest()
    state = state_home / 'dotfiles/restic' / identity
    report = {'repository': str(repo), 'drive_mounted': os.path.ismount(env['BACKUP_MOUNT']),
              'jobs': {}, 'snapshots': {}, 'services': {},
              'unfinished_captures': sorted(str(p) for p in root.glob('.system-backup-capture-*') if p.is_dir())}
    for job, interval in JOBS.items():
        report['jobs'][job] = completion(state / (job + '.success'), interval, time.time())
    for kind in ['system', 'applications']:
        path = root / 'system-backup/inventories' / (kind + '-metadata.json')
        try:
            record = json.loads(path.read_text())
            report['snapshots'][kind] = {'status': record.get('status', 'unknown'),
                                         'completed_at': record.get('completed_at')}
        except (OSError, ValueError, AttributeError):
            report['snapshots'][kind] = {'status': 'unknown', 'completed_at': None}
    for unit in UNITS:
        try:
            result = subprocess.run(['systemctl', '--user', 'show', unit, '--no-pager',
                                     '--property=LoadState,ActiveState,Result'],
                                    capture_output=True, text=True, timeout=5)
            if result.returncode:
                raise RuntimeError('User service manager unavailable')
            properties = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
            report['services'][unit] = properties
        except (OSError, RuntimeError, subprocess.TimeoutExpired):
            report['services'][unit] = {'LoadState': 'unknown', 'Result': 'unknown'}
    report['needs_attention'] = bool(report['unfinished_captures']) or any(
        job['status'] != 'current' for job in report['jobs'].values()) or any(
        snapshot['status'] != 'completed' for snapshot in report['snapshots'].values()) or any(
        unit.get('LoadState') != 'loaded' or unit.get('Result') != 'success'
        for unit in report['services'].values())
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    report = collect()
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print('Backup health (local records; repository contents not queried)')
        print(f"Repository: {report['repository']}")
        print('Drive: ' + ('mounted' if report['drive_mounted'] else 'offline'))
        for name, job in report['jobs'].items():
            print(f"{name}: {job['status']} — last successful run: {job['completed_at'] or 'not recorded'}")
        for name, snapshot in report['snapshots'].items():
            print(f"{name} snapshot: {snapshot['status']} — {snapshot['completed_at'] or 'date unknown'}")
        for name, unit in report['services'].items():
            print(f"{name}: {unit.get('LoadState', 'unknown')}, last result {unit.get('Result', 'unknown')}")
        print(f"Unfinished capture directories: {len(report['unfinished_captures'])}")
        for path in report['unfinished_captures']:
            print('  ' + path)
        if report['needs_attention']:
            print('Review missing/overdue records, service results, and unfinished captures above.')
    return 1 if report['needs_attention'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
