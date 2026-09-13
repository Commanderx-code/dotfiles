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


def run_job(job, if_due=False):
    repo = os.environ['RESTIC_REPOSITORY']
    mount = os.environ['BACKUP_MOUNT']
    if subprocess.run(['mountpoint', '-q', mount]).returncode != 0:
        print(f'{mount} is not mounted. Maintenance remains pending.')
        return 0
    if not Path(repo).is_dir():
        print(f'Restic repository missing: {repo}')
        return 1
    for command in ('restic', 'kwallet-query'):
        if not shutil.which(command):
            print(f'Required command missing: {command}')
            return 1
    state_home = Path(os.environ.get('XDG_STATE_HOME') or str(Path.home() / '.local/state'))
    identity = hashlib.sha256(os.fsencode(str(Path(repo).resolve()))).hexdigest()
    state = state_home / 'dotfiles/restic' / identity
    state.mkdir(parents=True, exist_ok=True)
    with (state / 'maintenance.lock').open('a') as lock:
        # Waiting lets simultaneous timer and mount triggers recheck the timestamp.
        fcntl.flock(lock, fcntl.LOCK_EX)
        stamp = state / (job + '.success')
        if if_due and stamp.exists() and 0 <= time.time() - stamp.stat().st_mtime < INTERVALS[job]:
            print(f'Restic {job} is up to date.')
            return 0
        password_command = shlex.join([
            'kwallet-query', '-f', os.environ['RESTIC_WALLET_FOLDER'],
            '-r', os.environ['RESTIC_WALLET_ENTRY'], os.environ['RESTIC_WALLET'],
        ])
        base = ['restic', '--repo', repo, '--password-command', password_command]
        commands = ([['forget', '--keep-daily', '7', '--keep-weekly', '5',
                      '--keep-monthly', '12', '--keep-yearly', '3', '--prune'], ['check']]
                    if job == 'maintenance' else [['check', '--read-data-subset=10%']])
        for command in commands:
            result = subprocess.run(base + command)
            if result.returncode:
                print(f'Restic {job} failed; successful completion date was not changed.')
                return result.returncode
        # Replacing a small file keeps readers from observing partial state.
        with tempfile.NamedTemporaryFile(dir=state, delete=False) as stream:
            temporary = Path(stream.name)
        try:
            temporary.replace(stamp)
        finally:
            temporary.unlink(missing_ok=True)
        print(f'Restic {job} completed successfully.')
        return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('job', choices=INTERVALS)
    parser.add_argument('--if-due', action='store_true')
    args = parser.parse_args()
    return run_job(args.job, args.if_due)


if __name__ == '__main__':
    raise SystemExit(main())
