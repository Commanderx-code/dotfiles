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
# The offsite backup runs daily on its own; two days allows for one missed run.
OFFSITE_JOBS = {'backup': 2 * 86400, 'maintenance': 7 * 86400, 'deep-check': 30 * 86400}
OFFSITE_UNITS = ['backup-offsite.service', 'restic-maintenance-offsite.service',
                 'restic-deep-check-offsite.service']
# The drive is connected by hand, so a reminder waits a few days rather than one.
REMIND_AFTER_DAYS = 3
OFFSITE_REMIND_AFTER_DAYS = 2


def completion(stamp, interval, now):
    if not stamp.exists():
        return {'status': 'unknown', 'completed_at': None}
    timestamp = stamp.stat().st_mtime
    age = now - timestamp
    return {'status': 'current' if 0 <= age < interval else 'overdue',
            'completed_at': datetime.datetime.fromtimestamp(timestamp, datetime.timezone.utc).isoformat(),
            'age_days': round(age / 86400, 2)}


def state_directory(env, repo, remote):
    """Mirror of restic-job's record location: local paths resolved, URLs hashed as written."""
    state_home = Path(env.get('XDG_STATE_HOME') or str(Path.home() / '.local/state'))
    key = repo if remote else str(Path(repo).resolve())
    return state_home / 'dotfiles/restic' / hashlib.sha256(os.fsencode(key)).hexdigest()


def unit_states(units):
    states = {}
    for unit in units:
        try:
            result = subprocess.run(['systemctl', '--user', 'show', unit, '--no-pager',
                                     '--property=LoadState,ActiveState,Result'],
                                    capture_output=True, text=True, timeout=5)
            if result.returncode:
                raise RuntimeError('User service manager unavailable')
            states[unit] = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
        except (OSError, RuntimeError, subprocess.TimeoutExpired):
            states[unit] = {'LoadState': 'unknown', 'Result': 'unknown'}
    return states


def collect(env=os.environ):
    repo = env['RESTIC_REPOSITORY']
    root = Path(env['DOTFILES_DIR'])
    state = state_directory(env, repo, remote=False)
    report = {'repository': repo, 'drive_mounted': os.path.ismount(env['BACKUP_MOUNT']),
              'jobs': {}, 'snapshots': {}, 'services': {}, 'offsite': None,
              'unfinished_captures': sorted(str(p) for p in root.glob('.system-backup-capture-*') if p.is_dir())}
    for job, interval in JOBS.items():
        report['jobs'][job] = completion(state / (job + '.success'), interval, time.time())
    if env.get('OFFSITE_REPOSITORY'):
        offsite_state = state_directory(env, env['OFFSITE_REPOSITORY'], remote=True)
        report['offsite'] = {'repository': env['OFFSITE_REPOSITORY'], 'jobs': {}, 'services': {}}
        for job, interval in OFFSITE_JOBS.items():
            report['offsite']['jobs'][job] = completion(offsite_state / (job + '.success'), interval, time.time())
    for kind in ['system', 'applications']:
        path = root / 'system-backup/inventories' / (kind + '-metadata.json')
        try:
            record = json.loads(path.read_text())
            report['snapshots'][kind] = {'status': record.get('status', 'unknown'),
                                         'completed_at': record.get('completed_at')}
        except (OSError, ValueError, AttributeError):
            report['snapshots'][kind] = {'status': 'unknown', 'completed_at': None}
    report['services'] = unit_states(UNITS)
    if report['offsite']:
        report['offsite']['services'] = unit_states(OFFSITE_UNITS)
    jobs = list(report['jobs'].values())
    services = list(report['services'].values())
    if report['offsite']:
        jobs += report['offsite']['jobs'].values()
        services += report['offsite']['services'].values()
    report['needs_attention'] = bool(report['unfinished_captures']) or any(
        job['status'] != 'current' for job in jobs) or any(
        snapshot['status'] != 'completed' for snapshot in report['snapshots'].values()) or any(
        unit.get('LoadState') != 'loaded' or unit.get('Result') != 'success' for unit in services)
    return report


def reminder(report):
    """The desktop notification to send when the last backup is too old, if any."""
    job = report['jobs']['backup']
    if job['completed_at'] and job['age_days'] < REMIND_AFTER_DAYS:
        return None
    age = f"{int(job['age_days'])} days ago" if job['completed_at'] else 'never recorded'
    step = 'Run backup-health for details.' if report['drive_mounted'] else 'Connect the backup drive to run it.'
    return 'Backup overdue', f'Last successful backup: {age}. {step}'


def offsite_reminder(report):
    """The notification for an offsite backup that stopped completing, if any."""
    if not report.get('offsite'):
        return None
    job = report['offsite']['jobs']['backup']
    if job['completed_at'] and job['age_days'] < OFFSITE_REMIND_AFTER_DAYS:
        return None
    age = f"{int(job['age_days'])} days ago" if job['completed_at'] else 'never recorded'
    return 'Offsite backup overdue', f'Last successful offsite backup: {age}. Run backup-health for details.'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--remind', action='store_true',
                        help='only send a desktop notification when the last backup is overdue')
    args = parser.parse_args()
    report = collect()
    if args.remind:
        for message in [reminder(report), offsite_reminder(report)]:
            if message:
                subprocess.run([os.environ.get('BACKUP_NOTIFIER', 'notify-send'), '--app-name=Backups', *message],
                               check=True)
        return 0
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
        if report['offsite']:
            print(f"Offsite repository: {report['offsite']['repository']}")
            for name, job in report['offsite']['jobs'].items():
                print(f"offsite {name}: {job['status']} — last successful run: {job['completed_at'] or 'not recorded'}")
            for name, unit in report['offsite']['services'].items():
                print(f"{name}: {unit.get('LoadState', 'unknown')}, last result {unit.get('Result', 'unknown')}")
        else:
            print('Offsite repository: not configured')
        print(f"Unfinished capture directories: {len(report['unfinished_captures'])}")
        for path in report['unfinished_captures']:
            print('  ' + path)
        if report['needs_attention']:
            print('Review missing/overdue records, service results, and unfinished captures above.')
    return 1 if report['needs_attention'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
