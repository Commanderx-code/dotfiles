#!/usr/bin/env python3
"""Write atomic, per-capture provenance without reading credentials."""
import argparse
import datetime
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile


def output(*args):
    try:
        result = subprocess.run(args, text=True, capture_output=True, timeout=10)
        return result.stdout.strip() if result.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired):
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    parser.add_argument('kind', choices=['system', 'applications'])
    parser.add_argument('status', choices=['started', 'completed'])
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    target = args.destination / f'{args.kind}-metadata.json'
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    if args.status == 'completed':
        record = json.loads(target.read_text())
        if record.get('status') != 'started':
            parser.error('no capture in progress')
        record.update(status='completed', completed_at=now)
    else:
        try:
            os_release = platform.freedesktop_os_release()
        except OSError:
            os_release = {}
        repo = os.environ.get('DOTFILES_DIR', str(Path(__file__).resolve().parents[2]))
        record = {
            'schema_version': 1,
            'kind': args.kind,
            'status': 'started',
            'started_at': now,
            'hostname': platform.node(),
            'kernel': platform.release(),
            'architecture': platform.machine(),
            'os': {key: os_release.get(key) for key in ('ID', 'PRETTY_NAME', 'VERSION_ID')},
            'dotfiles_revision': output('git', '-C', repo, 'rev-parse', 'HEAD'),
            'versions': {name: output(name, '--version') for name in ('pacman', 'flatpak', 'systemctl', 'nix', 'restic')},
        }
    # A failed write leaves the previous metadata intact.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', dir=args.destination, delete=False) as stream:
            temporary = Path(stream.name)
            json.dump(record, stream, indent=2)
            stream.write('\n')
        temporary.replace(target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
