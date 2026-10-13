#!/usr/bin/env python3
"""Move the pinned terminal tools to their latest GitHub releases."""
import hashlib
import os
from pathlib import Path
import re
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home-manager/scripts'))
from github_checks import api

PINS = Path('home-manager/terminal-tools.nix')
# One pinned download: a version, the release asset for it, and the asset's hash.
PIN = re.compile(r'version = "(?P<version>[^"]+)";\n(?P<indent>[ \t]*)'
                 r'url = "https://github\.com/(?P<repository>[\w.-]+/[\w.-]+)/releases/download/'
                 r'v(?P=version)/(?P<asset>[\w.+-]+)";\n(?P=indent)sha256 = "(?P<sha256>[0-9a-f]{64})";')
LIMIT = 512 * 1024 * 1024


def latest(repository):
    """The newest full release; GitHub leaves prereleases and drafts out."""
    tag = api(f'repos/{repository}/releases/latest')['tag_name']
    if not isinstance(tag, str) or not re.fullmatch(r'v[0-9][0-9A-Za-z.+-]*', tag):
        raise ValueError(f'Unexpected release tag for {repository}: {tag!r}')
    return tag[1:]


def digest(url):
    if not url.startswith('https://github.com/'):
        raise ValueError(f'Refusing to download {url}')
    sha256, size = hashlib.sha256(), 0
    with urllib.request.urlopen(url, timeout=120) as response:
        while chunk := response.read(1024 * 1024):
            size += len(chunk)
            if size > LIMIT:
                raise ValueError(f'{url} is larger than expected')
            sha256.update(chunk)
    return sha256.hexdigest()


def update(text, latest=latest, digest=digest):
    """Return the rewritten pins and one line per tool that moved."""
    changes = []

    def replace(pin):
        repository, old = pin['repository'], pin['version']
        new = latest(repository)
        if new == old:
            return pin[0]
        url = f'https://github.com/{repository}/releases/download/v{new}/{pin["asset"]}'
        changes.append(f'{repository.split("/")[1]} {old} -> {new}')
        indent = pin['indent']
        return f'version = "{new}";\n{indent}url = "{url}";\n{indent}sha256 = "{digest(url)}";'

    if not PIN.search(text):
        raise ValueError('No pinned downloads found')
    return PIN.sub(replace, text), changes


def main():
    path = ROOT / PINS
    text, changes = update(path.read_text())
    if changes:
        path.write_text(text)
    print('\n'.join(changes) if changes else 'Every pinned terminal tool is current.')
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.write(f'changed={str(bool(changes)).lower()}\nsummary={", ".join(changes)}\n')


if __name__ == '__main__':
    main()
