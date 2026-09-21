"""Exercise import ownership and local fast-forwards with disposable repositories."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home-manager/scripts'))
import github_checks as checks


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync = load('myfish_import', ROOT / 'scripts/sync-myfish.py')
updater = load('repo_updater', ROOT / 'home-manager/scripts/repo-update.py')


def record(**changes):
    return dict({'id': 1, 'run_attempt': 1, 'head_sha': 'a' * 40, 'event': 'push',
                 'head_branch': 'main', 'head_repository': {'full_name': 'Commanderx-code/Myfish'},
                 'status': 'completed', 'conclusion': 'success'}, **changes)


class ValidationTests(unittest.TestCase):
    def test_exact_latest_trusted_main_validation_required(self):
        for event in ('push', 'workflow_dispatch'):
            good = record(event=event)
            self.assertTrue(checks.tested('Myfish', 'a' * 40, lambda _: {'workflow_runs': [good]}))
        for records in ([], [record(event='pull_request')], [record(head_sha='b' * 40)],
                        [record(head_branch='other')], [record(head_repository={'full_name': 'other/Myfish'})],
                        [record(status='in_progress')], [record(conclusion='failure')],
                        [record(), record(id=2, conclusion='failure')],
                        [record(), record(run_attempt=2, conclusion='failure')]):
            with self.subTest(records=records):
                self.assertFalse(checks.tested('Myfish', 'a' * 40, lambda _: {'workflow_runs': records}))

    def test_api_failure_does_not_grant_eligibility(self):
        with self.assertRaises(OSError):
            checks.eligible('Myfish', lambda _: (_ for _ in ()).throw(OSError('offline')))

    def test_missing_validation_is_dispatched_and_existing_failure_is_not_retried(self):
        with patch.object(sync, 'api', return_value={'sha': 'a' * 40}), \
             patch.object(sync, 'check_runs', return_value=[]), patch.object(sync.subprocess, 'run') as run:
            sync.ensure_validation()
            self.assertIn('check.yml', run.call_args.args[0])
        with patch.object(sync, 'api', return_value={'sha': 'a' * 40}), \
             patch.object(sync, 'check_runs', return_value=[record(conclusion='failure')]), \
             patch.object(sync.subprocess, 'run') as run:
            sync.ensure_validation()
            run.assert_not_called()


class ImportTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / 'dotfiles'
        self.source = Path(temporary.name) / 'Myfish'
        (self.root / sync.FUNCTIONS).mkdir(parents=True)
        (self.source / 'modules/fish/functions').mkdir(parents=True)
        (self.root / sync.LOCK).write_text(json.dumps({'version': 1, 'repository': 'Commanderx-code/Myfish',
            'revision': 'a' * 40, 'overrides': {'personal.fish': 'workstation'}, 'files': {}}))
        self.shared = self.source / 'modules/fish/functions/shared.fish'
        self.shared.write_text('function shared; echo portable; end\n')
        (self.source / 'modules/fish/functions/personal.fish').write_text('upstream personal')
        (self.root / sync.FUNCTIONS / 'personal.fish').write_text('local personal')

    def test_import_update_removal_and_idempotence_preserve_overrides(self):
        self.assertTrue(sync.synchronize(self.root, self.source, 'b' * 40))
        self.assertFalse(sync.synchronize(self.root, self.source, 'b' * 40))
        self.assertEqual((self.root / sync.FUNCTIONS / 'personal.fish').read_text(), 'local personal')
        self.shared.write_text('function shared; echo new; end\n')
        self.assertTrue(sync.synchronize(self.root, self.source, 'c' * 40))
        self.assertIn('echo new', (self.root / sync.FUNCTIONS / 'shared.fish').read_text())
        self.shared.unlink()
        sync.synchronize(self.root, self.source, 'd' * 40)
        self.assertFalse((self.root / sync.FUNCTIONS / 'shared.fish').exists())
        sync.verify(self.root)

    def test_local_edits_and_new_name_collisions_fail_before_mutations(self):
        target = self.root / sync.FUNCTIONS / 'shared.fish'
        target.write_text('personal collision')
        with self.assertRaises(ValueError):
            sync.synchronize(self.root, self.source, 'b' * 40)
        self.assertEqual(target.read_text(), 'personal collision')
        target.unlink()
        sync.synchronize(self.root, self.source, 'b' * 40)
        manifest = (self.root / sync.LOCK).read_bytes()
        target.write_text('local edits')
        with self.assertRaises(ValueError):
            sync.synchronize(self.root, self.source, 'c' * 40)
        self.assertEqual(target.read_text(), 'local edits')
        self.assertEqual((self.root / sync.LOCK).read_bytes(), manifest)

    def test_symlinks_and_unsafe_names_rejected(self):
        self.shared.unlink()
        self.shared.symlink_to(self.root / sync.LOCK)
        with self.assertRaises(ValueError):
            sync.synchronize(self.root, self.source, 'b' * 40)
        for name in ('../outside.fish', '/outside.fish', 'x;echo.fish'):
            with self.assertRaises(ValueError):
                sync.filename(name)

    def test_committed_import_matches_manifest(self):
        sync.verify(ROOT)


class LocalUpdateTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.bare, self.author, self.local = [self.base / name for name in ('remote.git', 'author', 'dotfiles')]
        self.command('git', 'init', '--bare', '--initial-branch=main', str(self.bare))
        self.command('git', 'clone', str(self.bare), str(self.author))
        for root in (self.author,):
            self.command('git', '-C', str(root), 'config', 'user.name', 'Fixture')
            self.command('git', '-C', str(root), 'config', 'user.email', 'fixture@example.invalid')
        self.commit('initial')
        self.command('git', 'clone', str(self.bare), str(self.local))
        self.command('git', '-C', str(self.local), 'remote', 'set-url', 'origin', 'https://github.com/Commanderx-code/dotfiles.git')
        self.command('git', '-C', str(self.local), 'config', f'url.{self.bare}.insteadOf', 'https://github.com/Commanderx-code/dotfiles.git')
        self.before = updater.git(self.local, 'rev-parse', 'HEAD')
        self.commit('new')
        self.head = updater.git(self.author, 'rev-parse', 'HEAD')

    def command(self, *args):
        return subprocess.run(args, check=True, capture_output=True, text=True)

    def commit(self, text):
        (self.author / 'file').write_text(text)
        self.command('git', '-C', str(self.author), 'add', 'file')
        self.command('git', '-C', str(self.author), 'commit', '-m', text)
        self.command('git', '-C', str(self.author), 'push')

    def request(self, path):
        return {'workflow_runs': [record(head_sha=self.head, head_repository={'full_name': 'Commanderx-code/dotfiles'})]}

    def test_preview_and_apply_only_tested_fast_forward(self):
        result = updater.update(self.local, 'dotfiles', request=self.request)
        self.assertEqual(result['status'], 'available')
        self.assertEqual(updater.git(self.local, 'rev-parse', 'HEAD'), self.before)
        result = updater.update(self.local, 'dotfiles', apply=True, request=self.request)
        self.assertEqual(result['status'], 'updated')
        self.assertEqual(updater.git(self.local, 'rev-parse', 'HEAD'), self.head)
        self.assertEqual(updater.update(self.local, 'dotfiles', apply=True, request=self.request)['status'], 'current')

    def test_dirty_failed_ci_and_local_commits_do_not_get_overwritten(self):
        for name in ('file', 'untracked'):
            path = self.local / name
            old = path.read_bytes() if path.exists() else None
            path.write_text('unfinished')
            self.assertEqual(updater.update(self.local, 'dotfiles', True, self.request)['status'], 'skipped')
            self.assertEqual(path.read_text(), 'unfinished')
            path.write_bytes(old) if old else path.unlink()
        self.assertEqual(updater.update(self.local, 'dotfiles', True, lambda _: {'workflow_runs': []})['status'], 'waiting')
        self.command('git', '-C', str(self.local), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 'commit', '--allow-empty', '-m', 'local work')
        local_head = updater.git(self.local, 'rev-parse', 'HEAD')
        self.assertEqual(updater.update(self.local, 'dotfiles', True, self.request)['status'], 'skipped')
        self.assertEqual(updater.git(self.local, 'rev-parse', 'HEAD'), local_head)

    def test_wrong_origin_is_not_fetched(self):
        self.command('git', '-C', str(self.local), 'remote', 'set-url', 'origin', 'https://example.invalid/other.git')
        self.assertEqual(updater.update(self.local, 'dotfiles', True, self.request)['reason'], 'unexpected origin URL')

    def test_detached_checkout_and_in_progress_merge_are_skipped(self):
        self.command('git', '-C', str(self.local), 'checkout', '--detach')
        self.assertEqual(updater.update(self.local, 'dotfiles', True, self.request)['reason'], 'detached checkout')
        self.command('git', '-C', str(self.local), 'checkout', 'main')
        (self.local / '.git/MERGE_HEAD').write_text(self.head + '\n')
        self.assertEqual(updater.update(self.local, 'dotfiles', True, self.request)['reason'], 'Git operation in progress')

    def test_ignored_local_file_cannot_be_overwritten_by_incoming_tracked_file(self):
        (self.local / '.git/info/exclude').write_text('future\n')
        (self.local / 'future').write_text('personal ignored file')
        (self.author / 'future').write_text('incoming')
        self.command('git', '-C', str(self.author), 'add', 'future')
        self.commit('incoming tracked file')
        self.head = updater.git(self.author, 'rev-parse', 'HEAD')
        with self.assertRaises(subprocess.CalledProcessError):
            updater.update(self.local, 'dotfiles', True, self.request)
        self.assertEqual(updater.git(self.local, 'rev-parse', 'HEAD'), self.before)
        self.assertEqual((self.local / 'future').read_text(), 'personal ignored file')

    def test_failed_toolbox_build_is_not_marked_complete_and_can_retry(self):
        state = {}
        with patch.object(updater, 'safe_checkout', return_value=None), \
             patch.object(updater, 'git', return_value=self.head), \
             patch.object(updater.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, ['cargo'])):
            with self.assertRaises(subprocess.CalledProcessError):
                updater.build_toolbox(self.local, self.head, state)
        self.assertNotIn('toolbox_built', state)
        with patch.object(updater, 'safe_checkout', return_value=None), \
             patch.object(updater, 'git', return_value=self.head), \
             patch.object(updater.subprocess, 'run'):
            self.assertTrue(updater.build_toolbox(self.local, self.head, state))
        self.assertEqual(state['toolbox_built'], self.head)

    def test_toolbox_requires_a_complete_published_release(self):
        good = {'tag_name': 'toolbox-' + self.head[:12], 'draft': False, 'prerelease': False,
                'assets': [{'name': 'commander-toolbox-linux-x86_64'}, {'name': 'SHA256SUMS'}]}
        self.assertTrue(updater.released_toolbox(self.head, lambda _: [good]))
        for release in (dict(good, draft=True), dict(good, assets=[]), dict(good, tag_name='other')):
            self.assertFalse(updater.released_toolbox(self.head, lambda _: [release]))
