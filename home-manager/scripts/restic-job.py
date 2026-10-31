#!/usr/bin/env python3
"""Serialize maintenance and record successful completion per repository."""
import argparse
import fcntl
import hashlib
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import time

INTERVALS = {'maintenance': 7 * 86400, 'deep-check': 30 * 86400}


def repository(offsite):
    """Where a job runs, or None when the offsite repository is not configured."""
    if offsite:
        repo = os.environ.get('OFFSITE_REPOSITORY')
        if not repo:
            return None
        return {'repo': repo, 'entry': os.environ.get('OFFSITE_WALLET_ENTRY', 'Offsite'),
                'remote': True, 'lock': 'backup-offsite.lock', 'held': 'OFFSITE_LOCK_HELD'}
    return {'repo': os.environ['RESTIC_REPOSITORY'], 'entry': os.environ.get('RESTIC_WALLET_ENTRY', ''),
            'remote': False, 'lock': 'backup-personal.lock', 'held': 'BACKUP_LOCK_HELD'}


def state_directory(target):
    """Per-repository record directory; remote URLs are hashed as written."""
    state_home = Path(os.environ.get('XDG_STATE_HOME') or str(Path.home() / '.local/state'))
    key = target['repo'] if target['remote'] else str(Path(target['repo']).resolve())
    state = state_home / 'dotfiles/restic' / hashlib.sha256(os.fsencode(key)).hexdigest()
    state.mkdir(parents=True, exist_ok=True)
    return state


def wallet_command(entry):
    return ['kwallet-query', '-f', os.environ['RESTIC_WALLET_FOLDER'], '-r', entry, os.environ['RESTIC_WALLET']]


def credentials(target):
    """Extra environment Restic needs: S3 credentials from the wallet for a remote repository."""
    if not target['remote']:
        return {}
    env = dict(os.environ)
    for variable, suffix in [('AWS_ACCESS_KEY_ID', '-key-id'), ('AWS_SECRET_ACCESS_KEY', '-key')]:
        result = subprocess.run(wallet_command(target['entry'] + suffix), capture_output=True, text=True)
        value = result.stdout.strip() if result.returncode == 0 else ''
        if not value:
            raise LookupError(f"No wallet entry '{target['entry'] + suffix}'; run: backup-offsite --setup")
        env[variable] = value
    return {'env': env}


def backup_lock(name='backup-personal.lock', held='BACKUP_LOCK_HELD'):
    """Wait for the lock that manual and on-mount backups hold, unless the caller has it."""
    runtime = os.environ.get('XDG_RUNTIME_DIR')
    if os.environ.get(held) or not runtime:
        return None
    handle = (Path(runtime) / name).open('a')
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print('A backup is running; waiting for it to finish...', flush=True)
        fcntl.flock(handle, fcntl.LOCK_EX)
    return handle


def record(state, name):
    # Replacing a small file keeps readers from observing partial state.
    with tempfile.NamedTemporaryFile(dir=state, delete=False) as stream:
        temporary = Path(stream.name)
    try:
        temporary.replace(state / name)
    finally:
        temporary.unlink(missing_ok=True)


def run_job(job, if_due=False, offsite=False):
    target = repository(offsite)
    if target is None:
        print('Offsite backup is not configured; nothing to maintain.')
        return 0
    if not target['remote']:
        mount = os.environ['BACKUP_MOUNT']
        if subprocess.run(['mountpoint', '-q', mount]).returncode != 0:
            print(f'{mount} is not mounted. Maintenance remains pending.')
            return 0
        if not Path(target['repo']).is_dir():
            print(f"Restic repository missing: {target['repo']}")
            return 1
    for command in ('restic', 'kwallet-query'):
        if not shutil.which(command):
            print(f'Required command missing: {command}')
            return 1
    state = state_directory(target)
    # Pruning and checking lock the repository exclusively, so a backup running
    # at the same time would fail; held until this function returns.
    backup = backup_lock(target['lock'], target['held'])  # noqa: F841
    with (state / 'maintenance.lock').open('a') as lock:
        # Waiting lets simultaneous timer and mount triggers recheck the timestamp.
        fcntl.flock(lock, fcntl.LOCK_EX)
        stamp = state / (job + '.success')
        if if_due and stamp.exists() and 0 <= time.time() - stamp.stat().st_mtime < INTERVALS[job]:
            print(f'Restic {job} is up to date.')
            return 0
        try:
            extra = credentials(target)
        except LookupError as error:
            print(error)
            return 1
        base = ['restic', '--repo', target['repo'],
                '--password-command', shlex.join(wallet_command(target['entry']))]
        commands = ([['forget', '--keep-daily', '7', '--keep-weekly', '5',
                      '--keep-monthly', '12', '--keep-yearly', '3', '--prune'], ['check']]
                    if job == 'maintenance' else [['check', '--read-data-subset=10%']])
        for command in commands:
            result = subprocess.run(base + command, **extra)
            if result.returncode:
                print(f'Restic {job} failed; successful completion date was not changed.')
                return result.returncode
        record(state, stamp.name)
        print(f'Restic {job} completed successfully.')
        return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('job', choices=[*INTERVALS, 'record-backup'])
    parser.add_argument('--if-due', action='store_true')
    parser.add_argument('--offsite', action='store_true', help='act on the offsite repository')
    args = parser.parse_args()
    if args.job == 'record-backup':
        target = repository(args.offsite)
        if target is None:
            print('Offsite backup is not configured; nothing recorded.')
            return 1
        record(state_directory(target), 'backup.success')
        return 0
    return run_job(args.job, args.if_due, args.offsite)


if __name__ == '__main__':
    raise SystemExit(main())
