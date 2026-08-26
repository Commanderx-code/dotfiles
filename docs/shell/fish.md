---
title: Fish Shell
category: Shell
managed_by: Home Manager
source: ~/dotfiles/configs/fish
runtime: ~/.config/fish
tags: fish shell home-manager fzf aliases functions
status: active
criticality: important
last_verified: 2026-08-26
---
# Fish Shell

## Overview
Fish is the primary interactive shell. Home Manager enables Fish, zoxide integration, and fzf integration, then recursively links `configs/fish/conf.d` and `configs/fish/functions` into `~/.config/fish`.

## Source of Truth
- `~/dotfiles/configs/fish/`
- `~/dotfiles/home-manager/modules/fish.nix`

## Apply Changes
```fish
hms
```
For brand-new files in this Git-backed flake, stage them first:
```fish
cd ~/dotfiles
git add path/to/new/file
hms
```

## Keybindings
| Key | Action |
|---|---|
| `Ctrl-P` | `fzf_open_file` |
| `Ctrl-F` | `fzf_rg_search` |
| `Ctrl-H` | fzf history |
| `Ctrl-R` | intentionally unbound |
| `Tab` | normal completion, or fzf picker when token ends in `**` |

## High-impact command overrides
`vim -> nvim`, `cat -> bat`, `grep -> rg`, `find -> fd`, `rm -> trash -v`, `cp -> cp -i`, `mv -> mv -i`, `mkdir -> mkdir -p`.

Escape hatches: `ccat`, `cgrep`, `cfind`, or `command <name>`.
