"""Exercise picker injection and privileged installation with disposable fixtures."""
import base64
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import shutil
import stat
import struct
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / path))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(name, loader))
    loader.exec_module(module)
    return module


results = load('search_results', 'configs/scripts/fzf-rg-results')
installer = load('system_install', 'home-manager/scripts/restore-system-files.py')


class SearchSecurity(unittest.TestCase):
    def test_rg_picker_opens_literal_paths_without_executing_filename(self):
        for name in ('ordinary.txt', 'report:(touch marker):notes.txt',
                     'report:1;touch marker;#.txt', 'space\ttab\nnewline.txt',
                     '+command-\x1b.txt', os.fsdecode(b'nonutf8-\xff.txt'), 'long-line.txt'):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                directory = Path(temporary)
                (directory / name).write_text('first\nneedle' + ('x' * 150000 if name == 'long-line.txt' else '') + '\n')
                bin_dir = directory / 'bin'
                bin_dir.mkdir()
                for tool, body in {
                    'fzf': "import os,sys\ndata=sys.stdin.buffer.read().split(b'\\0')\nsys.stdout.buffer.write(data[0]+b'\\0') if data[0] else None\n",
                    'nvim': "import json,os,sys\nopen(os.environ['TEST_LOG'],'w').write(json.dumps(sys.argv[1:]))\n",
                }.items():
                    file = bin_dir / tool
                    file.write_text('#!/usr/bin/env python3\n' + body)
                    file.chmod(0o700)
                log = directory / 'args.json'
                code = '''source "$argv[1]"
function commandline
    if test "$argv[1]" = -r
        set -g test_command "$argv[3]"
    else
        eval "$test_command"
    end
end
fzf_rg_search
'''
                run = subprocess.run(['fish', '--no-config', '-c', code,
                                      str(ROOT / 'configs/fish/functions/fzf_rg_search.fish')],
                                     cwd=directory, input='needle\n', text=True, capture_output=True,
                                     env=dict(os.environ, HOME=str(directory), TEST_LOG=str(log),
                                              PATH=str(bin_dir) + ':' + os.environ['PATH']))
                self.assertEqual(run.returncode, 0, run.stderr)
                self.assertFalse((directory / 'marker').exists())
                self.assertEqual(json.loads(log.read_text()), ['+2', '--', str(directory / name)])

    def test_invalid_metadata_is_rejected_before_preview(self):
        path = base64.b64encode(b'/safe/file').decode()
        for line, encoded in [('1;touch marker', path), ('0', path), ('-1', path),
                              ('1', '!!'), ('1', base64.b64encode(b'/x\0y').decode()),
                              ('1', base64.b64encode(b'-option').decode())]:
            with self.subTest(line=line, path=encoded), self.assertRaises(ValueError):
                results.location(line, encoded)

    def test_byte_paths_and_preview_are_argument_data(self):
        path = b'/tmp/a:\xff\n.txt'
        event = {'type': 'match', 'data': {'path': {'bytes': base64.b64encode(path).decode()},
                 'line_number': 3, 'lines': {'text': 'needle\n'}}}
        row, = results.rows([json.dumps(event)])
        self.assertEqual(row.count(b'\0'), 1)
        line, encoded, display = row[:-1].decode().split('\t', 2)
        self.assertNotIn('\n', display)
        self.assertEqual(results.location(line, encoded), (path, '3'))
        with patch.object(results.sys, 'argv', ['helper', 'preview', line, encoded]), \
             patch.object(results.subprocess, 'run') as run:
            results.main()
            self.assertEqual(run.call_args.args[0][-2:], ['--', path])


class RestoreSecurity(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        # Ordinary test runs check requested root ownership; fakeroot runs check metadata too.
        self.chown = patch.object(installer.os, 'fchown', wraps=os.fchown if os.geteuid() == 0 else None)
        self.owners = self.chown.start()
        self.addCleanup(self.chown.stop)

    def deploy(self, source, destination):
        staged = self.root / 'staged'
        installer.stage(str(source), staged)
        fd = os.open(destination.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            if destination.exists() or destination.is_symlink():
                installer.harden(destination.name, fd)
            installer.install(staged, destination.name, fd)
        finally:
            os.close(fd)

    def test_new_and_existing_tree_ownership_modes_and_open_descriptors(self):
        source = self.root / 'snapshot'
        source.mkdir()
        for name, mode in [('grub', 0o664), ('hook', 0o775), ('private', 0o600)]:
            (source / name).write_text('restored')
            (source / name).chmod(mode)
        destination = self.root / 'installed'
        destination.mkdir(mode=0o777)
        old = destination / 'grub'
        old.write_text('old')
        extra = destination / 'extra'
        extra.write_text('preserved')
        old.chmod(0o666)
        extra.chmod(0o666)
        if os.geteuid() == 0:
            for p in [source, *source.iterdir(), destination, old, extra]:
                os.chown(p, 1000, 1000)
        with extra.open('r+') as stale:
            self.deploy(source, destination)
            stale.write('tampered')
            stale.flush()
        self.assertEqual(extra.read_text(), 'preserved')
        self.assertEqual(old.read_text(), 'restored')
        for p in [destination, *destination.iterdir()]:
            self.assertFalse(p.stat().st_mode & 0o022)
            if os.geteuid() == 0:
                self.assertEqual((p.stat().st_uid, p.stat().st_gid), (0, 0))
        self.assertEqual(stat.S_IMODE((destination / 'hook').stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE((destination / 'private').stat().st_mode), 0o600)
        self.assertTrue(self.owners.call_args_list)
        self.assertTrue(all(call.args[1:] == (0, 0) for call in self.owners.call_args_list))

    def test_source_symlinks_and_special_files_fail_before_installation(self):
        source = self.root / 'snapshot'
        source.mkdir()
        outside = self.root / 'outside'
        outside.write_text('untouched')
        destination = self.root / 'installed'
        (source / 'link').symlink_to(outside)
        with self.assertRaises(OSError):
            self.deploy(source, destination)
        self.assertFalse(destination.exists())
        self.assertEqual(outside.read_text(), 'untouched')
        (source / 'link').unlink()
        os.mkfifo(source / 'fifo')
        shutil.rmtree(self.root / 'staged')
        with self.assertRaises(ValueError):
            self.deploy(source, destination)

    def test_destination_links_are_never_followed(self):
        source = self.root / 'snapshot'
        source.write_text('new')
        outside = self.root / 'outside'
        outside.write_text('untouched')
        destination = self.root / 'installed'
        destination.symlink_to(outside)
        with self.assertRaises(OSError):
            self.deploy(source, destination)
        self.assertEqual(outside.read_text(), 'untouched')

    def test_existing_directory_acls_do_not_survive_restore(self):
        source = self.root / 'snapshot'
        source.mkdir()
        destination = self.root / 'installed'
        destination.mkdir(mode=0o755)
        acl = struct.pack('<I', 2) + b''.join(struct.pack('<HHI', tag, permissions, uid)
            for tag, permissions, uid in [(1, 7, 0xffffffff), (2, 7, 12345),
                                          (4, 5, 0xffffffff), (16, 7, 0xffffffff),
                                          (32, 5, 0xffffffff)])
        os.setxattr(destination, 'system.posix_acl_default', acl)
        self.deploy(source, destination)
        self.assertNotIn('system.posix_acl_default', os.listxattr(destination))
        (destination / 'later').write_text('root-created')
        self.assertNotIn('system.posix_acl_access', os.listxattr(destination / 'later'))

    def test_failed_directory_restore_recovers_safe_modes(self):
        source = self.root / 'snapshot'
        source.mkdir(mode=0o755)
        source.chmod(0o755)
        (source / 'new').write_text('new')
        destination = self.root / 'installed'
        destination.mkdir(mode=0o755)
        destination.chmod(0o755)
        (destination / 'link').symlink_to(self.root / 'outside')
        with self.assertRaises(OSError):
            self.deploy(source, destination)
        self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o755)
        (destination / 'link').unlink()
        fd = os.open(self.root, os.O_RDONLY | os.O_DIRECTORY)
        try:
            with patch.object(installer.shutil, 'copyfileobj', side_effect=OSError('full disk')):
                with self.assertRaises(OSError):
                    installer.install(source, destination.name, fd)
            self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o755)
        finally:
            os.close(fd)

    @unittest.skipUnless(os.geteuid() == 0, 'Run under fakeroot for privileged metadata integration')
    def test_full_restore_repairs_owner_and_creates_new_destinations(self):
        source = self.root / 'snapshot'
        source.mkdir()
        (source / 'grub').write_text('restored')
        os.chown(source / 'grub', 1000, 1000)
        destination = self.root / 'etc' / 'defaults'
        installer.restore(source, destination)
        self.assertEqual((destination / 'grub').stat().st_uid, 0)
        os.chown(destination / 'grub', 1000, 1000)
        installer.restore(source / 'grub', destination / 'grub')
        self.assertEqual((destination / 'grub').stat().st_uid, 0)
        self.assertEqual((destination / 'grub').read_text(), 'restored')

    def test_destination_hardlinks_and_failed_writes_do_not_touch_other_files(self):
        source = self.root / 'snapshot'
        source.write_text('new')
        outside = self.root / 'outside'
        outside.write_text('untouched')
        destination = self.root / 'installed'
        os.link(outside, destination)
        with self.assertRaises(ValueError):
            self.deploy(source, destination)
        self.assertEqual(outside.read_text(), 'untouched')
        destination.unlink()
        fd = os.open(self.root, os.O_RDONLY | os.O_DIRECTORY)
        try:
            with patch.object(installer.shutil, 'copyfileobj', side_effect=OSError('full disk')):
                with self.assertRaises(OSError):
                    installer.install(source, destination.name, fd)
            self.assertFalse(destination.exists())
            self.assertFalse(list(self.root.glob('.restore-*')))
        finally:
            os.close(fd)

    def test_all_privileged_restore_copies_use_shared_boundary(self):
        source = (ROOT / 'home-manager/scripts/restore-system.fish').read_text()
        restore_sections = source.split('section SDDM', 1)[1]
        self.assertEqual(restore_sections.count('restore_system_files '), 11)
        self.assertNotIn('sudo cp', restore_sections)
        self.assertIn('sudo cp -a "$source" "$target"', source)
        self.assertIn('cp -a "$BACKUP/plasma/config/."', source)


if __name__ == '__main__':
    unittest.main()
