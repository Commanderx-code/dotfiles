#!/usr/bin/env python3
"""Fast-forward clean source checkouts to tested main revisions; rebuild Helix Toolbox."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess
import tempfile

from github_checks import OWNER, SOURCES, api, revision, tested


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True, timeout=120).strip()


def safe_checkout(root, name):
    if not (root / '.git').exists():
        return 'missing checkout'
    if git(root, 'rev-parse', '--show-toplevel') != str(root.resolve()):
        return 'unexpected repository root'
    remote = git(root, 'config', '--get', 'remote.origin.url')
    allowed = set()
    for repository in ORIGIN_NAMES.get(name, (name,)):
        expected = f'github.com/{OWNER}/{repository}'
        allowed |= {'https://' + expected, 'git@' + expected.replace('.com/', '.com:')}
    if remote.removesuffix('.git') not in allowed:
        return 'unexpected origin URL'
    if git(root, 'status', '--porcelain', '--untracked-files=all'):
        return 'unfinished local edits'
    try:
        git(root, 'symbolic-ref', '--quiet', '--short', 'HEAD')
    except subprocess.CalledProcessError:
        return 'detached checkout'
    try:
        upstream = git(root, 'rev-parse', '--abbrev-ref', '@{upstream}')
    except subprocess.CalledProcessError:
        return 'branch has no upstream'
    if upstream != 'origin/main':
        return 'branch does not track origin/main'
    for marker in ('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply', 'BISECT_START'):
        path = Path(git(root, 'rev-parse', '--git-path', marker))
        if (path if path.is_absolute() else root / path).exists():
            return 'Git operation in progress'
    return None


TOOLBOX = 'Helix-toolbox'
# The local checkout may use the repository name or a lowercase directory
# name, from before the rename to Helix Toolbox (HelixForge) too.
CHECKOUT_NAMES = {TOOLBOX: ('Helix-toolbox', 'helix-toolbox', 'Helix-Forge', 'helixforge')}
# GitHub forwards the old name, so a checkout made before the rename may keep it.
ORIGIN_NAMES = {TOOLBOX: ('Helix-toolbox', 'Helix-Forge')}


def checkout_root(projects, name):
    candidates = [projects / directory for directory in CHECKOUT_NAMES.get(name, (name,))]
    return next((root for root in candidates if root.exists()), candidates[0])


def released_toolbox(head, request=api):
    head = revision(head)
    # Releases are tagged vX.Y.Z and name the commit they were built from.
    # Listing avoids treating an expected unpublished revision as an API error.
    releases = request(f'repos/{OWNER}/{TOOLBOX}/releases?per_page=100')
    for release in releases:
        if release['target_commitish'] == head and not release['draft'] and not release['prerelease']:
            names = {asset['name'] for asset in release['assets']}
            return {'helix-toolbox-linux-x86_64', 'SHA256SUMS'} <= names
    return False


def update(root, name, apply=False, request=api):
    reason = safe_checkout(root, name)
    if reason:
        return {'repository': name, 'status': 'skipped', 'reason': reason}
    git(root, 'fetch', '--quiet', 'origin', 'refs/heads/main:refs/remotes/origin/main')
    before = revision(git(root, 'rev-parse', 'HEAD'))
    head = revision(git(root, 'rev-parse', 'origin/main'))
    if git(root, 'rev-list', '--count', 'origin/main..HEAD') != '0':
        return {'repository': name, 'status': 'skipped', 'reason': 'local commits ahead of or diverged from origin/main'}
    eligible = released_toolbox(head, request) if name == TOOLBOX else tested(name, head, request)
    if not eligible:
        return {'repository': name, 'status': 'waiting', 'reason': 'remote main is awaiting successful validation or release'}
    result = {'repository': name, 'before': before, 'revision': head,
              'status': 'current' if before == head else 'available'}
    if apply and before != head:
        reason = safe_checkout(root, name)
        if reason or git(root, 'rev-parse', 'HEAD') != before:
            return {'repository': name, 'status': 'skipped', 'reason': reason or 'checkout changed during update'}
        git(root, 'merge', '--ff-only', '--no-overwrite-ignore', head)
        result['status'] = 'updated'
    return result


def build_toolbox(root, head, state):
    binary = root / 'target/debug/helix-toolbox'
    if state.get('toolbox_built') == head and binary.is_file():
        return False
    reason = safe_checkout(root, TOOLBOX)
    if reason or git(root, 'rev-parse', 'HEAD') != head:
        raise RuntimeError('Helix Toolbox checkout changed before build: ' + (reason or 'different commit'))
    subprocess.run(['cargo', 'build', '--locked', '--package', 'helix-toolbox'], cwd=root, check=True, timeout=1200)
    subprocess.run([str(binary), '--help'], cwd=root, check=True, stdout=subprocess.DEVNULL, timeout=30)
    if safe_checkout(root, TOOLBOX) or git(root, 'rev-parse', 'HEAD') != head:
        raise RuntimeError('Helix Toolbox checkout changed during build; not marking this revision built')
    state['toolbox_built'] = head
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--projects-dir', type=Path, default=Path.home() / 'github/projects')
    parser.add_argument('--apply', action='store_true', help='apply eligible fast-forwards; default only fetches and reports')
    args = parser.parse_args()
    directory = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'repo-update'
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (directory / 'lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print(json.dumps({'status': 'skipped', 'reason': 'updater already running'}))
            return
        path = directory / 'state.json'
        state = json.loads(path.read_text()) if path.exists() else {}
        results = []
        for name in SOURCES:
            try:
                root = checkout_root(args.projects_dir, name)
                result = update(root, name, args.apply)
                if args.apply and name == TOOLBOX and result['status'] in ('current', 'updated'):
                    result['rebuilt'] = build_toolbox(root, result['revision'], state)
            except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
                result = {'repository': name, 'status': 'error', 'reason': str(error)}
            results.append(result)
        with tempfile.NamedTemporaryFile(mode='w', dir=directory, delete=False) as tmp:
            json.dump(dict(state, last_results=results), tmp, indent=2)
            tmp.write('\n')
        os.replace(tmp.name, path)
        print(json.dumps(results, indent=2))
        if any(result['status'] == 'error' for result in results):
            raise SystemExit(1)


if __name__ == '__main__':
    main()
