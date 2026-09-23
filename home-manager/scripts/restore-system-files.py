#!/usr/bin/env python3
"""Install snapshot files as root-owned system data, without following symlinks."""
import argparse
import errno
import os
from pathlib import Path
import shutil
import stat
import tempfile
import uuid


FLAGS = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK


def clear_acls(fd):
    # Reused directories must not confer their former owner's ACLs on future files.
    for attribute in ('system.posix_acl_access', 'system.posix_acl_default'):
        try:
            os.removexattr(fd, attribute)
        except OSError as error:
            if error.errno not in (errno.ENODATA, errno.ENOTSUP):
                raise


def safe_mode(info):
    # Preserve restrictive and executable modes, but never writable ACL masks or set-ID bits.
    mode = stat.S_IMODE(info.st_mode) & 0o755
    return mode | 0o700 if stat.S_ISDIR(info.st_mode) else mode


def stage(source, destination, parent_fd=None):
    fd = os.open(source, FLAGS, dir_fd=parent_fd)
    try:
        info = os.fstat(fd)
        if stat.S_ISDIR(info.st_mode):
            destination.mkdir(mode=0o700)
            for name in os.listdir(fd):
                stage(name, destination / name, fd)
        elif stat.S_ISREG(info.st_mode):
            with os.fdopen(os.dup(fd), 'rb') as incoming, destination.open('xb') as outgoing:
                shutil.copyfileobj(incoming, outgoing)
        else:
            raise ValueError('Snapshot must contain only regular files and directories')
        destination.chmod(safe_mode(info))
        os.utime(destination, ns=(info.st_atime_ns, info.st_mtime_ns))
    finally:
        os.close(fd)


def secure_parent(destination):
    """Walk fixed system parents by descriptor; never traverse a mutable or linked parent."""
    fd = os.open('/', FLAGS | os.O_DIRECTORY)
    try:
        for name in destination.parent.parts[1:]:
            try:
                os.mkdir(name, mode=0o755, dir_fd=fd)
            except FileExistsError:
                pass
            child = os.open(name, FLAGS | os.O_DIRECTORY, dir_fd=fd)
            os.close(fd)
            fd = child
            info = os.fstat(fd)
            if info.st_uid != 0 or (info.st_mode & 0o022 and not info.st_mode & stat.S_ISVTX):
                raise ValueError(f'Unsafe restore parent: {destination.parent}')
        return fd
    except BaseException:
        os.close(fd)
        raise


def harden(name, parent_fd):
    """Repair preexisting ownership without following links or changing shared inodes."""
    fd = os.open(name, FLAGS, dir_fd=parent_fd)
    try:
        info = os.fstat(fd)
        directory = stat.S_ISDIR(info.st_mode)
        if not directory and (not stat.S_ISREG(info.st_mode) or info.st_nlink != 1):
            raise ValueError('Restore destination contains a special file or hard link')
        if directory:
            os.fchown(fd, 0, 0)
            # Lock the directory before inspecting children its former owner could alter.
            os.fchmod(fd, 0o700)
            try:
                clear_acls(fd)
                for child in os.listdir(fd):
                    harden(child, fd)
            finally:
                os.fchmod(fd, safe_mode(info))
        else:
            # Replacing the inode revokes any writable descriptors held by the former owner.
            with os.fdopen(os.dup(fd), 'rb') as incoming:
                replace_file(incoming, info, name, parent_fd)
    finally:
        os.close(fd)


def replace_file(incoming, info, name, parent_fd):
    temporary = '.restore-' + uuid.uuid4().hex
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600, dir_fd=parent_fd)
    try:
        with os.fdopen(os.dup(fd), 'wb') as outgoing:
            shutil.copyfileobj(incoming, outgoing)
        os.fchown(fd, 0, 0)
        clear_acls(fd)
        os.fchmod(fd, safe_mode(info))
        os.utime(fd, ns=(info.st_atime_ns, info.st_mtime_ns))
        os.replace(temporary, name, src_dir_fd=parent_fd, dst_dir_fd=parent_fd)
    finally:
        os.close(fd)
        try:
            os.unlink(temporary, dir_fd=parent_fd)
        except FileNotFoundError:
            pass


def install(source, name, parent_fd):
    info = source.stat()
    if source.is_dir():
        try:
            os.mkdir(name, mode=0o700, dir_fd=parent_fd)
        except FileExistsError:
            pass
        fd = os.open(name, FLAGS | os.O_DIRECTORY, dir_fd=parent_fd)
        try:
            os.fchown(fd, 0, 0)
            os.fchmod(fd, 0o700)
            try:
                clear_acls(fd)
                for child in source.iterdir():
                    install(child, child.name, fd)
            finally:
                os.fchmod(fd, safe_mode(info))
            os.utime(fd, ns=(info.st_atime_ns, info.st_mtime_ns))
        finally:
            os.close(fd)
    else:
        # Atomic replacement also breaks any existing file ownership/ACL association.
        with source.open('rb') as incoming:
            replace_file(incoming, info, name, parent_fd)


def restore(source, destination):
    if os.geteuid() != 0:
        raise PermissionError('System file restoration requires root')
    destination = Path(os.path.abspath(destination))
    if destination == Path('/'):
        raise ValueError('Refusing to restore over the filesystem root')
    os.umask(0o077)
    # Finish reading the user-owned snapshot before touching the privileged destination.
    with tempfile.TemporaryDirectory(prefix='system-restore-') as temporary:
        staged = Path(temporary) / 'content'
        stage(os.path.abspath(source), staged)
        parent = secure_parent(destination)
        try:
            try:
                harden(destination.name, parent)
            except FileNotFoundError:
                pass
            install(staged, destination.name, parent)
        finally:
            os.close(parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    try:
        restore(args.source, args.destination)
    except (OSError, ValueError) as error:
        parser.exit(1, f'System restore failed: {error}\n')
