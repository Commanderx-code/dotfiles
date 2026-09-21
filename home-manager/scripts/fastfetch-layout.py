#!/usr/bin/env python3
"""Fit the existing Fastfetch artwork and boxed sections to the terminal grid."""

import argparse
import copy
import json
import os
from pathlib import Path
import re
import sys
import unicodedata

SGR = re.compile(r'\x1b\[[0-9;:]*m')
CONTROL = re.compile(r'\x1b(?:\[[0-?]*[ -/]*[@-~]|\].*?(?:\x07|\x1b\\)|.)', re.S)
BORDER_CURSOR = re.compile(r'\x1b\[s\x1b\[\d+C│\x1b\[u│ ')
RESET = '\x1b[0m'


def plain(text):
    return SGR.sub('', text)


def cell_width(char):
    # Nerd Font private-use icons occupy one cell, combining marks none.
    if unicodedata.combining(char) or unicodedata.category(char) in ('Cf', 'Cc'):
        return 0
    return 2 if unicodedata.east_asian_width(char) in ('W', 'F') else 1


def width(text):
    return sum(cell_width(char) for char in plain(text))


def wrap(text, columns):
    """Wrap colored text without cutting escape sequences or losing characters."""
    text = CONTROL.sub(lambda m: m[0] if SGR.fullmatch(m[0]) else '', text)
    text = ''.join(c for c in text if c == '\x1b' or ord(c) >= 32)
    tokens = re.findall(r'\x1b\[[0-9;:]*m|[^\x1b]', text)
    line, active, used = '', '', 0
    for token in tokens:
        if SGR.fullmatch(token):
            active = '' if token in ('\x1b[m', RESET) else active + token
            line += token
            continue
        size = cell_width(token)
        if used + size > columns:
            yield line + RESET
            line, used = active, 0
        line += token
        used += size
    yield line + RESET


def prepared_config(config):
    """Let native Fastfetch detect/format every original field, without borders."""
    result = copy.deepcopy(config)
    result['logo'] = {'type': 'none'}
    result.setdefault('display', {}).update(disableLinewrap=False)
    for module in result['modules']:
        if isinstance(module, dict):
            for key in ('key', 'format'):
                if key in module:
                    module[key] = BORDER_CURSOR.sub('', module[key])
    return result


def boxed_lines(output, columns):
    color = '32'
    inside = False
    for line in output.splitlines():
        text = plain(line)
        heading = re.fullmatch(r'╭─ (.*?) ─+╮', text)
        if heading:
            colors = re.findall(r'\x1b\[(3[0-7])m', line)
            color = colors[-1] if colors else '32'
            ink = f'\x1b[{color}m'
            title = heading[1]
            if width(title) + 6 <= columns:
                yield ink + '╭─ ' + title + ' ' + '─' * (columns - width(title) - 5) + '╮' + RESET
            else:
                yield ink + '╭' + '─' * (columns - 2) + '╮' + RESET
                for part in wrap(ink + title, columns - 4):
                    yield ink + '│ ' + part + ' ' * (columns - 3 - width(part)) + ink + '│' + RESET
            inside = True
        elif re.fullmatch(r'╰─+╯', text):
            yield f'\x1b[{color}m╰' + '─' * (columns - 2) + '╯' + RESET
            yield ''
            inside = False
        elif inside:
            ink = f'\x1b[{color}m'
            for part in wrap(line, columns - 4):
                yield ink + '│ ' + part + ' ' * (columns - 3 - width(part)) + ink + '│' + RESET
        else:
            yield from wrap(line, columns)


def layout(config, columns, rows, output):
    result = copy.deepcopy(config)
    columns = max(10, columns)
    logo = result['logo']
    # Keep the source artwork, size, colors and all fields. Only its placement
    # changes. Leave a spare terminal column to avoid the autowrap boundary.
    logo_width = int(logo.get('width', 24))
    side = columns >= 106 + logo_width + 5
    if columns < 35 or rows < 15:
        logo['type'] = 'none'
        side = False
    else:
        logo.pop('height', None)
        logo.update(position='left' if side else 'top',
                    padding={'left': 0, 'right': 3 if side else 0, 'top': 0},
                    printRemaining=True)
    box_width = min(106, columns - 1 - (logo_width + 3 if side else 0))
    lines = list(boxed_lines(output, box_width))
    if not side and logo['type'] != 'none':
        # Kitty top images may leave the cursor at the right of their last row.
        lines.insert(0, '\r')
    result.setdefault('display', {}).update(disableLinewrap=False)
    # Native Fastfetch handles the image protocol and spacing. Escape literal
    # opening braces in detected values so they cannot become format tokens.
    result['modules'] = [{'type': 'custom', 'format': line.replace('{', '{{')}
                         for line in lines]
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--columns', type=int, default=80)
    parser.add_argument('--lines', type=int, default=24)
    parser.add_argument('--config', type=Path, default=Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'fastfetch/config.jsonc')
    args = parser.parse_args()
    config = json.loads(args.config.read_text())
    result = prepared_config(config) if args.prepare else layout(config, args.columns, args.lines, sys.stdin.read())
    print(json.dumps(result))


if __name__ == '__main__':
    main()
