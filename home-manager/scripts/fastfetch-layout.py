#!/usr/bin/env python3
"""Produce a Fastfetch layout that fits the current terminal's grid."""

import argparse
import copy
import json
import os
from pathlib import Path


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
    # The tree-style keys carry no cursor positions or borders, so only the
    # bare "break" spacers are dropped; every module is kept as written.
    modules += [copy.deepcopy(module) for module in config['modules'] if not isinstance(module, str)]
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
