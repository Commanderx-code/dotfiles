#!/usr/bin/env python3
"""Refuse a push that adds a private value. Git runs this as a pre-push hook.

The values stay out of every repository, in the private directory: push-guard.txt
holds "label pattern" lines (a literal in any case, or a regex after re:), and homelab.inventory
holds NAME=value rows of addresses. Output names the label, never the value.
`git push --no-verify` overrides a false alarm.
"""
import os
from pathlib import Path
import re
import subprocess
import sys

PRIVATE = Path(os.environ.get('PUSH_GUARD_DIR') or Path.home() / '.local/share/helix-private')
# Shown in full is noise: a few lines say what to fix, and the first fix repeats.
MAX_FINDINGS = 20
ADDRESS_END = r'(?!\d|\.\d)'
ADDRESS_START = r'(?<![\d.])'
MAC = re.compile(r'(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}', re.I)
# A stand-in that test code uses everywhere, even when the inventory lists it.
PLACEHOLDER_MAC = '00:11:22:33:44:55'


def patterns():
    """(label, compiled pattern) pairs, or None when this machine has no private values."""
    found = []
    labelled = PRIVATE / 'push-guard.txt'
    inventory = PRIVATE / 'homelab.inventory'
    if not labelled.exists() and not inventory.exists():
        return None
    if labelled.exists():
        for line in labelled.read_text().splitlines():
            if not line.strip() or line.startswith('#'):
                continue
            label, pattern = line.split(None, 1)
            found.append((label, re.compile(pattern[3:]) if pattern.startswith('re:')
                          else re.compile(re.escape(pattern), re.I)))
    if inventory.exists():
        for line in inventory.read_text().splitlines():
            name, separator, value = line.strip().partition('=')
            if not separator or not value or name.endswith('_MAC_END') or value.lower() == PLACEHOLDER_MAC:
                continue
            if name.endswith('_PREFIX'):
                found.append((name, re.compile(ADDRESS_START + re.escape(value) + r'\.\d')))
            elif MAC.fullmatch(value):
                found.append((name, re.compile('[:-]'.join(re.escape(part) for part in re.split('[:-]', value)), re.I)))
            else:
                found.append((name, re.compile(ADDRESS_START + re.escape(value) + ADDRESS_END)))
    return found


def revisions(remote, local, known):
    """What this push adds: past the remote's old tip when we have it, else past all it holds."""
    if set(known) != {'0'} and subprocess.run(['git', 'cat-file', '-e', known + '^{commit}'],
                                              capture_output=True).returncode == 0:
        return [f'{known}..{local}']
    return [local, '--not', '--remotes=' + remote]


def findings(revs, checks):
    """(commit, where, label) for each private value in commit details and added lines."""
    log = subprocess.Popen(['git', 'log', '--no-color', '--no-ext-diff', '--no-textconv', '-U0',
                            '--format=%x00%H%n%an <%ae>%n%cn <%ce>%n%B%x00', *revs],
                           stdout=subprocess.PIPE)
    commit, where, details, seen = '', '', False, []
    # One pass over each line; the labels are worked out only for a line that hits.
    anything = re.compile('|'.join(f"(?{'i' if pattern.flags & re.I else ''}:{pattern.pattern})"
                                   for _, pattern in checks))

    def check(text):
        if not anything.search(text):
            return
        for label, pattern in checks:
            entry = (commit, where, label)
            if pattern.search(text) and entry not in seen:
                seen.append(entry)

    for raw in log.stdout:
        line = raw.decode('utf-8', 'replace').rstrip('\n')
        if details:
            if line.endswith('\0'):
                details = False
                line = line[:-1]
            check(line)
        elif line.startswith('\0'):
            commit, where, details = line[1:13], 'commit details', True
        elif line.startswith('+++ '):
            where = line[6:] if line.startswith('+++ b/') else line[4:]
        elif line.startswith('+'):
            check(line[1:])
    if log.wait():
        raise SystemExit('push-guard: git log failed; nothing was checked.')
    return seen


def main():
    checks = patterns()
    if checks is None:
        print(f'push-guard: no private values in {PRIVATE}, so this push was not checked.', file=sys.stderr)
        return 0
    remote = sys.argv[1] if len(sys.argv) > 1 else 'origin'
    found = []
    for line in sys.stdin:
        _, local, _, known = line.split()
        if set(local) != {'0'}:
            found += [entry for entry in findings(revisions(remote, local, known), checks) if entry not in found]
    if not found:
        return 0
    print('push-guard: this push adds private values:', file=sys.stderr)
    for commit, where, label in found[:MAX_FINDINGS]:
        print(f'  {commit}  {where}: {label}', file=sys.stderr)
    if len(found) > MAX_FINDINGS:
        print(f'  and {len(found) - MAX_FINDINGS} more', file=sys.stderr)
    print('Fix the commits, or use git push --no-verify if this is a false alarm.', file=sys.stderr)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
