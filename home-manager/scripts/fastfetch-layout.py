#!/usr/bin/env python3
"""Produce a Fastfetch layout that fits the current terminal's grid."""

import argparse
import copy
import json
import os
from pathlib import Path
import re


def layout(config, columns, rows):
    config = copy.deepcopy(config)
    # Adapt presentation, never the set of information. A short window can
    # scroll; silently dropping modules made resizing appear to lose data.
    logo = config['logo']
    if columns < 35 or rows < 15:
        logo['type'] = 'none'
    elif columns < 150:
        # A side image leaves too little room for the package and theme rows.
        # Above the text, long values can wrap without crossing the image.
        logo.pop('height', None)
        logo.update(position='top', width=24, padding={'right': 0}, printRemaining=True)
    else:
        logo.pop('height', None)
        logo.update(position='left', width=24, padding={'right': 3}, printRemaining=True)
    config.setdefault('display', {}).update(disableLinewrap=False)
    # Kitty's top image can leave the cursor to the right of its bottom row.
    # Explicitly finish that row before the first heading. Image spacing is
    # output, not a nonexistent logo.padding.bottom setting.
    modules = [{'type': 'custom', 'format': '\r'}] if logo.get('position') == 'top' and logo['type'] != 'none' else []
    section = ''
    for original in config['modules']:
        if isinstance(original, str):
            continue
        module = copy.deepcopy(original)
        kind = module['type']
        if kind == 'custom':
            value = module.get('format', '')
            heading = re.fullmatch(r'\{#(\d+)\}╭─ (.*?) ─+╮\{#0\}', value)
            if heading:
                color, title = heading.groups()
                section = title
                if modules:
                    modules.append({'type': 'custom', 'format': ' '})
                module['format'] = '{#' + color + '}' + title + ' ──{#0}'
                modules.append(module)
            elif 'colors' in section and '╰' not in value:
                module['format'] = re.sub(r'\x1b\[s\x1b\[\d+C│\x1b\[u│ ', '', value)
                modules.append(module)
            continue
        if 'key' in module:
            key = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', module['key'])
            module['key'] = re.sub(r'\{#[^}]*\}', '', key).lstrip('│ ')
        modules.append(module)
    config['modules'] = modules
    return config


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--columns', type=int, default=80)
    parser.add_argument('--lines', type=int, default=24)
    parser.add_argument('--config', type=Path, default=Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'fastfetch/config.jsonc')
    args = parser.parse_args()
    config = json.loads(args.config.read_text())
    print(json.dumps(layout(config, max(10, args.columns), max(4, args.lines))))


if __name__ == '__main__':
    main()
