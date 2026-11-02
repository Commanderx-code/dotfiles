"""push-guard stops added private values, says where, and never repeats a value."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GUARD = ROOT / 'home-manager/scripts/push-guard.py'
ZERO = '0' * 40


class PushGuardTests(unittest.TestCase):
    def setUp(self):
        fixture = tempfile.TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        self.private = self.root / 'private'
        self.private.mkdir()
        (self.private / 'push-guard.txt').write_text(
            '# a comment\nemail someone@private.example\nname re:\\bJordan\\b\n')
        (self.private / 'homelab.inventory').write_text(
            'NAS_IP=203.0.113.7\nLAN_PREFIX=198.51.100\nTV_MAC=aa:bb:cc:dd:ee:01\nWAN_MAC_END=dd:ee:02\n'
            'FAKE_MAC=00:11:22:33:44:55\n')
        self.env = {**os.environ, 'PUSH_GUARD_DIR': str(self.private), 'GIT_CONFIG_GLOBAL': '/dev/null',
                    'GIT_CONFIG_NOSYSTEM': '1', 'GIT_AUTHOR_NAME': 'Tester', 'GIT_COMMITTER_NAME': 'Tester',
                    'GIT_AUTHOR_EMAIL': 'tester@example.invalid', 'GIT_COMMITTER_EMAIL': 'tester@example.invalid'}
        self.bare = self.root / 'remote.git'
        self.work = self.root / 'work'
        subprocess.run(['git', 'init', '-q', '--bare', '-b', 'main', str(self.bare)], check=True, env=self.env)
        subprocess.run(['git', 'clone', '-q', str(self.bare), str(self.work)], check=True, env=self.env,
                       capture_output=True)
        self.git('switch', '-q', '-c', 'main')
        self.write('README.md', 'A clean first line\n', 'First')
        self.git('push', '-q', 'origin', 'main')

    def git(self, *arguments, **options):
        return subprocess.run(['git', *arguments], cwd=self.work, env={**self.env, **options.pop('env', {})},
                              check=True, capture_output=True, text=True, **options).stdout.strip()

    def write(self, name, text, message='Change', **options):
        (self.work / name).write_text(text)
        self.git('add', name)
        self.git('commit', '-q', '-m', message, **options)
        return self.git('rev-parse', 'HEAD')

    def guard(self, local=None, known=None, env=None):
        local = local or self.git('rev-parse', 'HEAD')
        known = known or self.git('rev-parse', 'origin/main')
        return subprocess.run([sys.executable, '-I', str(GUARD), 'origin'], cwd=self.work,
                              env={**self.env, **(env or {})}, input=f'refs/heads/main {local} refs/heads/main {known}\n',
                              capture_output=True, text=True)

    def assert_blocked(self, result, label):
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn(label, result.stderr)

    def test_a_clean_push_passes_silently(self):
        self.write('notes.md', 'Nothing private here\n')
        result = self.guard()
        self.assertEqual((result.returncode, result.stderr), (0, ''))

    def test_an_added_email_is_named_by_label_and_never_printed(self):
        self.write('notes.md', 'Write to SOMEONE@private.example today\n')
        result = self.guard()
        self.assert_blocked(result, 'notes.md: email')
        self.assertNotIn('private.example', result.stderr.lower())

    def test_commit_identity_and_message_count(self):
        self.write('a.md', 'one\n', env={'GIT_AUTHOR_EMAIL': 'someone@private.example'})
        self.assert_blocked(self.guard(), 'commit details: email')
        self.git('reset', '-q', '--hard', 'origin/main')
        self.write('b.md', 'two\n', 'Thanks to Jordan')
        self.assert_blocked(self.guard(), 'commit details: name')

    def test_a_name_pattern_keeps_its_word_boundaries(self):
        self.write('notes.md', 'A Jordanian recipe\n')
        self.assertEqual(self.guard().returncode, 0)
        self.write('notes.md', 'Jordan was here\n')
        self.assert_blocked(self.guard(), 'name')

    def test_an_address_matches_exactly(self):
        self.write('near.md', '203.0.113.70 and 1203.0.113.7 and 203.0.113.7.5\n')
        self.assertEqual(self.guard().returncode, 0)
        self.write('exact.md', 'host 203.0.113.7:8080\n')
        self.assert_blocked(self.guard(), 'exact.md: NAS_IP')

    def test_a_prefix_needs_a_host_and_a_mac_matches_any_spelling(self):
        self.write('near.md', '198.51.100 alone and dd:ee:02 and 00:11:22:33:44:55\n')
        self.assertEqual(self.guard().returncode, 0)
        self.write('host.md', 'gateway 198.51.100.1\n')
        self.assert_blocked(self.guard(), 'host.md: LAN_PREFIX')
        self.git('reset', '-q', '--hard', 'origin/main')
        self.write('mac.md', 'AA-BB-CC-DD-EE-01\n')
        self.assert_blocked(self.guard(), 'mac.md: TV_MAC')

    def test_only_what_the_push_adds_counts(self):
        self.write('old.md', 'host 203.0.113.7\n')
        self.git('push', '-q', '--no-verify', 'origin', 'main')
        self.write('old.md', 'host removed\n')
        self.assertEqual(self.guard().returncode, 0)

    def test_a_new_branch_is_checked_against_what_the_remote_holds(self):
        self.git('switch', '-q', '-c', 'topic')
        self.write('notes.md', 'host 203.0.113.7\n')
        self.assert_blocked(self.guard(known=ZERO), 'notes.md: NAS_IP')

    def test_deleting_a_branch_checks_nothing(self):
        self.assertEqual(self.guard(local=ZERO, known=self.git('rev-parse', 'HEAD')).returncode, 0)

    def test_an_added_line_that_looks_like_a_file_header_is_still_read(self):
        self.write('notes.md', '++ Jordan was here\n')
        result = self.guard()
        self.assert_blocked(result, 'notes.md: name')
        self.assertNotIn('Jordan', result.stderr)

    def test_a_removed_line_that_looks_like_a_header_does_not_end_the_hunk(self):
        self.write('notes.md', '-- old\nkept\n')
        self.git('push', '-q', 'origin', 'main')
        self.write('notes.md', 'host 203.0.113.7\nkept\n')
        self.assert_blocked(self.guard(), 'notes.md: NAS_IP')

    def test_text_added_in_a_merge_commit_is_read(self):
        self.git('switch', '-q', '-c', 'topic')
        self.write('topic.md', 'clean\n')
        self.git('switch', '-q', 'main')
        self.write('main.md', 'clean\n')
        self.git('merge', '-q', '--no-commit', '--no-ff', 'topic')
        (self.work / 'main.md').write_text('host 203.0.113.7\n')
        self.git('add', 'main.md')
        self.git('commit', '-q', '-m', 'Merge topic')
        self.assert_blocked(self.guard(), 'main.md: NAS_IP')

    def test_an_annotated_tag_is_read_through_nested_tags(self):
        self.git('tag', '-a', 'inner', '-m', 'Thanks to Jordan')
        self.git('tag', '-a', 'outer', '-m', 'Clean', 'inner')
        result = self.guard(local=self.git('rev-parse', 'outer'))
        self.assert_blocked(result, 'tag details: name')

    def test_a_clean_annotated_tag_passes(self):
        self.git('tag', '-a', 'v1', '-m', 'A release')
        self.assertEqual(self.guard(local=self.git('rev-parse', 'v1')).returncode, 0)

    def test_a_machine_without_private_values_warns_and_pushes(self):
        self.write('notes.md', 'host 203.0.113.7\n')
        result = self.guard(env={'PUSH_GUARD_DIR': str(self.root / 'absent')})
        self.assertEqual(result.returncode, 0)
        self.assertIn('not checked', result.stderr)

    def test_git_runs_it_as_a_configured_hook(self):
        self.write('notes.md', 'host 203.0.113.7\n')
        self.git('config', 'hook.push-guard.event', 'pre-push')
        self.git('config', 'hook.push-guard.command', f'{sys.executable} -I {GUARD}')
        pushed = subprocess.run(['git', 'push', '-q', 'origin', 'main'], cwd=self.work, env=self.env,
                                capture_output=True, text=True)
        self.assertNotEqual(pushed.returncode, 0)
        self.assertIn('notes.md: NAS_IP', pushed.stderr)
        self.assertEqual(self.git('rev-parse', 'origin/main'),
                         self.git('rev-parse', 'HEAD~1'))
        self.git('push', '-q', '--no-verify', 'origin', 'main')


if __name__ == '__main__':
    unittest.main()
