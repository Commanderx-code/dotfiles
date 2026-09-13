#!/usr/bin/env python3
"""Publish complete Linux snapshots with an atomic directory exchange."""
import argparse
import ctypes
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def exchange(left, right):
    # Linux renameat2(RENAME_EXCHANGE): no interval with a missing destination.
    libc = ctypes.CDLL(None, use_errno=True)
    rename = libc.renameat2
    rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(-100, os.fsencode(left), -100, os.fsencode(right), 2) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error))


def capture(destination, command, kind):
    destination = Path(destination).absolute()
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink():
        raise ValueError('Snapshot destination must be a directory, not a symlink')
    previous = destination.with_name('.system-backup.previous')
    with destination.with_name('.system-backup.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        stage = Path(tempfile.mkdtemp(prefix='.system-backup-capture-', dir=destination.parent))
        published = False
        try:
            # Preserve files maintained by the other capture and manually saved assets.
            if destination.exists():
                shutil.copytree(destination, stage, dirs_exist_ok=True, symlinks=True)
            metadata = stage / 'inventories' / f'{kind}-metadata.json'
            # Never mistake an old completion record for this capture's success.
            metadata.unlink(missing_ok=True)
            result = subprocess.run(command + ['--capture', str(stage)])
            if result.returncode:
                raise RuntimeError(f'Capture exited with status {result.returncode}')
            record = json.loads(metadata.read_text())
            if record.get('status') != 'completed' or record.get('kind') != kind:
                raise RuntimeError('Capture did not record successful completion')
            if destination.exists():
                exchange(stage, destination)
            else:
                stage.rename(destination)
            published = True
            if stage.exists():
                if previous.exists():
                    if previous.is_symlink():
                        raise ValueError('Previous snapshot must not be a symlink')
                    exchange(stage, previous)
                    shutil.rmtree(stage)
                else:
                    stage.rename(previous)
            print(f'Snapshot published: {destination}')
            if previous.exists():
                print(f'Previous snapshot: {previous}')
            return 0
        except Exception as error:
            if published:
                print(f'Snapshot published, but previous-snapshot cleanup failed: {error}')
            else:
                print(f'Capture failed; published snapshot unchanged: {error}')
            if stage.exists():
                print(f'Retained working directory for inspection: {stage}')
            return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('kind', choices=['system', 'applications'])
    parser.add_argument('destination', type=Path)
    parser.add_argument('script')
    args = parser.parse_args()
    return capture(args.destination, ['fish', '--no-config', args.script], args.kind)


if __name__ == '__main__':
    raise SystemExit(main())
