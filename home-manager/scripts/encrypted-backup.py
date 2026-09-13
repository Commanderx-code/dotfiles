#!/usr/bin/env python3
"""Encrypt separate recovery files with one passphrase held only in memory."""
import argparse
import getpass
import os
from pathlib import Path
import subprocess
import sys
import time
import warnings


def encrypt(output, passphrase, *, archive=None, data=None):
    # A pipe keeps the passphrase out of argv, the environment, and disk files.
    read_fd, write_fd = os.pipe()
    producer = None
    try:
        os.write(write_fd, passphrase + b'\n')
        os.close(write_fd)
        write_fd = None
        with os.fdopen(os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'wb') as target:
            if archive:
                base, directory = archive
                excludes = ['--exclude=S.gpg-agent*', '--exclude=S.dirmngr',
                            '--exclude=*.lock', '--exclude=.#*', '--exclude=random_seed'] if directory == '.gnupg' else []
                producer = subprocess.Popen(['tar', '-C', str(base), *excludes,
                                             '-czf', '-', directory], stdout=subprocess.PIPE)
            result = subprocess.run(
                ['gpg', '--batch', '--yes', '--pinentry-mode', 'loopback',
                 '--passphrase-fd', str(read_fd), '--no-symkey-cache',
                 '--symmetric', '--cipher-algo', 'AES256'],
                stdin=producer.stdout if producer else None,
                input=data if producer is None else None,
                stdout=target, pass_fds=(read_fd,))
            if producer:
                producer.stdout.close()
                tar_status = producer.wait()
            else:
                tar_status = 0
            if result.returncode or tar_status:
                raise RuntimeError('Encryption failed')
    except FileExistsError:
        raise
    except BaseException:
        output.unlink(missing_ok=True)
        raise
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
        if producer and producer.poll() is None:
            producer.terminate()
            producer.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--with-restic-credential', action='store_true')
    parser.add_argument('--credential-only', action='store_true')
    args = parser.parse_args()
    os.umask(0o077)
    args.destination.mkdir(parents=True, exist_ok=True)
    credential = None
    if args.with_restic_credential or args.credential_only:
        subprocess.run(['mountpoint', '-q', os.environ['BACKUP_MOUNT']], check=True)
        credential = subprocess.check_output(['kwallet-query', '-f', os.environ['RESTIC_WALLET_FOLDER'],
                                              '-r', os.environ['RESTIC_WALLET_ENTRY'], os.environ['RESTIC_WALLET']])
        if not credential.strip():
            raise RuntimeError('KWallet returned an empty Restic password')
    # Refuse getpass's insecure fallback when no controlling terminal exists.
    with warnings.catch_warnings():
        warnings.simplefilter('error', getpass.GetPassWarning)
        passphrase = getpass.getpass('Recovery encryption passphrase (used for this entire run): ').encode()
    if not passphrase or b'\n' in passphrase or b'\r' in passphrase or len(passphrase) > 1024:
        raise ValueError('Passphrase must be nonempty, single-line, and at most 1024 bytes')
    timestamp = time.strftime('%Y-%m-%d_%H-%M-%S')
    home = Path.home()
    count = 0
    if not args.credential_only:
        for base, directory, label in [(home, '.ssh', 'ssh'), (home, '.gnupg', 'gnupg'),
                                       (home / '.local/share', 'kwalletd', 'kwallet')]:
            if not (base / directory).is_dir():
                continue
            output = args.destination / f'{label}-{timestamp}.tar.gz.gpg'
            encrypt(output, passphrase, archive=(base, directory))
            print(f'Created {output}', flush=True)
            count += 1
    if credential is not None:
        output = args.destination / f'restic-password-{timestamp}.txt.gpg'
        encrypt(output, passphrase, data=credential)
        print(f'Created {output}', flush=True)
        count += 1
    if not count:
        raise RuntimeError('No secret directories found; nothing backed up')
    print('Encrypted backup complete. Keep the recovery passphrase separately and test decryption.')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (Exception, KeyboardInterrupt) as error:
        print(f'Encrypted backup failed: {error}', file=sys.stderr)
        sys.exit(1)
