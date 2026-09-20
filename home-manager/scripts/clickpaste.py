#!/usr/bin/env python3
"""Type clipboard text into the window you focus during a short countdown."""

import argparse
import math
import os
import shutil
import subprocess
import sys
import time


def dotool_actions(text):
    """Encode clipboard data as literal type actions, never as dotool commands."""
    if any(ord(char) < 32 and char not in '\n\r\t' or ord(char) == 127 for char in text):
        raise ValueError('Clipboard contains unsupported control characters; nothing was typed.')
    lines = text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    actions = []
    for line_number, line in enumerate(lines):
        if line_number:
            actions.append('key enter\n')
        for column, segment in enumerate(line.split('\t')):
            if column:
                actions.append('key tab\n')
            # Keep each action below dotool's input scanner limit, including UTF-8.
            for start in range(0, len(segment), 1024):
                actions.append('type ' + segment[start:start + 1024] + '\n')
    return ''.join(actions).encode('utf-8')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--delay', type=float, default=3, metavar='SECONDS')
    parser.add_argument('--check', action='store_true', help='check dependencies without reading or typing the clipboard')
    args = parser.parse_args(argv)
    if not math.isfinite(args.delay) or not 0 <= args.delay <= 60:
        parser.error('--delay must be between 0 and 60 seconds')

    wayland = os.environ.get('XDG_SESSION_TYPE') == 'wayland' or bool(os.environ.get('WAYLAND_DISPLAY'))
    reader = ['wl-paste', '--no-newline', '--type', 'text'] if wayland else ['xclip', '-selection', 'clipboard', '-o']
    writer = ['dotool'] if wayland else ['xdotool', 'type', '--clearmodifiers', '--file', '-']
    for tool in (reader[0], writer[0]):
        if not shutil.which(tool):
            print(f'clickpaste: required command not found: {tool}', file=sys.stderr)
            return 1
    if wayland and not os.access('/dev/uinput', os.W_OK):
        print('clickpaste: your user needs write access to /dev/uinput for Wayland typing.', file=sys.stderr)
        return 1
    if args.check:
        print(f"clickpaste: {'Wayland' if wayland else 'X11'} dependencies ready ({reader[0]} + {writer[0]}).")
        return 0

    clipboard = subprocess.run(reader, capture_output=True, timeout=10)
    if clipboard.returncode:
        print('clickpaste: could not read clipboard text; nothing was typed.', file=sys.stderr)
        return 1
    text = clipboard.stdout.decode('utf-8')
    if not text:
        print('clickpaste: clipboard is empty; nothing to type.')
        return 0
    actions = dotool_actions(text)
    payload = actions if wayland else clipboard.stdout
    print(f'Typing clipboard in {args.delay:g} seconds. Click the destination; Ctrl+C cancels.', flush=True)
    time.sleep(args.delay)
    # Clipboard contents travel over stdin, not process arguments or temp files.
    result = subprocess.run(writer, input=payload, capture_output=True)
    if result.returncode or result.stderr:
        print('clickpaste: typing failed or some characters could not be typed. '
              'For characters outside your keyboard layout, use normal paste.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print('\nclickpaste: cancelled.', file=sys.stderr)
        sys.exit(130)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f'clickpaste: {error}', file=sys.stderr)
        sys.exit(1)
