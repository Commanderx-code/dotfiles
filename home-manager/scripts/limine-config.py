#!/usr/bin/env python3
"""Render Limine configuration for restore-limine; nothing here writes to the system.

appearance CONF FRAGMENT      merge the key: value lines of FRAGMENT into the
                              global section of CONF, before its first "/" entry
cmdline FILE ACTION WORD...   edit KERNEL_CMDLINE[default] in FILE (set, add or
                              remove the words); set replaces a word with the same
                              name= as well
"""
import re
import shlex
import sys

MARKER = '# Boot menu appearance from dotfiles (restore-limine).'
KEY = re.compile(r'^[ \t]*([a-z_]+)[ \t]*:')
CMDLINE = re.compile(r'^([ \t]*KERNEL_CMDLINE\[(?:"default"|default)\]\+?=)(.*)$', re.M)


def merge_appearance(current, fragment):
    settings = []
    for line in fragment.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        match = KEY.match(stripped)
        if not match:
            raise ValueError(f'Not a Limine setting: {stripped}')
        settings.append((match.group(1), stripped))
    keys = {key for key, _ in settings}
    lines = current.splitlines()
    # The global section ends where the first boot entry starts.
    end = next((index for index, line in enumerate(lines) if line.lstrip().startswith('/')), len(lines))
    kept = []
    for line in lines[:end]:
        match = KEY.match(line)
        if (match and match.group(1) in keys) or line.strip() == MARKER:
            continue
        kept.append(line)
    while kept and not kept[-1].strip():
        kept.pop()
    block = ([''] if kept else []) + [MARKER] + [line for _, line in settings]
    entries = lines[end:]
    if entries:
        block.append('')
    return '\n'.join(kept + block + entries).rstrip('\n') + '\n'


def render_cmdline(text, action, words):
    matches = list(CMDLINE.finditer(text))
    if not matches:
        raise ValueError('No KERNEL_CMDLINE[default] line; add one with the current kernel parameters first.')
    match = matches[-1]
    try:
        current = ' '.join(shlex.split(match.group(2), comments=True)).split()
    except ValueError as error:
        raise ValueError(f'Cannot read KERNEL_CMDLINE[default]: {error}')
    if action == 'add':
        updated = current + [word for word in words if word not in current]
    elif action == 'remove':
        updated = [word for word in current if word not in words]
    elif action == 'set':
        names = {word.split('=', 1)[0] for word in words if '=' in word}
        updated = [word for word in current
                   if word not in words and not ('=' in word and word.split('=', 1)[0] in names)] + list(words)
    else:
        raise ValueError('Unknown kernel parameter action.')
    if any('"' in word or '\n' in word for word in updated):
        raise ValueError('Kernel parameters cannot contain quotes.')
    value = '"' + ' '.join(updated) + '"'
    return text[:match.start()] + match.group(1) + value + text[match.end():]


def main():
    mode, path, *args = sys.argv[1:]
    with open(path) as handle:
        text = handle.read()
    if mode == 'appearance':
        with open(args[0]) as handle:
            print(merge_appearance(text, handle.read()), end='')
    elif mode == 'cmdline':
        print(render_cmdline(text, args[0], args[1:]), end='')
    else:
        raise ValueError('Unknown mode.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as error:
        sys.exit(str(error))
