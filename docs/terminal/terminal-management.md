---
title: Terminal Configuration Management
category: Terminal
managed_by: Home Manager
source: ~/dotfiles/home-manager/modules/terminal.nix
runtime: ~/.config + ~/.local/share/konsole + ~/.local/bin
tags: terminal konsole fzf-preview home-manager
status: active
criticality: normal
last_verified: 2026-08-26
---

# Terminal Configuration Management

Home Manager's terminal module currently manages:

```text
~/.local/bin/fzf-preview
~/.config/konsolerc
~/.local/share/konsole/Garuda.profile
~/.local/share/konsole/Sweet.colorscheme
```

## Source Files

```text
~/dotfiles/configs/scripts/fzf-preview
~/dotfiles/configs/konsole/konsolerc
~/dotfiles/configs/konsole/Garuda.profile
~/dotfiles/configs/konsole/Sweet.colorscheme
```

## Apply

```fish
hms
```

## Relationship to Fish

Konsole launches `/usr/bin/fish`, while the fzf preview helper is used by the custom Fish/fzf workflow documented in Batch 1.
