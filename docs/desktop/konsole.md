---
title: Konsole
category: Terminal
managed_by: Home Manager
source: ~/dotfiles/configs/konsole
runtime: ~/.config/konsolerc + ~/.local/share/konsole
tags: konsole terminal fish sweet home-manager
status: active
criticality: normal
last_verified: 2026-08-26
---

# Konsole

## Home Manager Wiring

`home-manager/modules/terminal.nix` installs:

```text
~/dotfiles/configs/konsole/konsolerc
  -> ~/.config/konsolerc

~/dotfiles/configs/konsole/Garuda.profile
  -> ~/.local/share/konsole/Garuda.profile

~/dotfiles/configs/konsole/Sweet.colorscheme
  -> ~/.local/share/konsole/Sweet.colorscheme
```

## Default Profile

```text
Garuda.profile
```

## Shell

Konsole launches:

```text
/usr/bin/fish
```

## Font

```text
MesloLGS Nerd Font 12
```

## Profile Behavior

- 110 columns
- blinking cursor
- auto-copy selected text
- trims leading/trailing spaces from selections
- underlines files
- unlimited/history mode setting `1`

## Color Scheme

`Sweet.colorscheme` uses:

```text
background: 22,25,37
foreground: 195,199,209
opacity: 0.8
blur: true
```

## Global Konsole Settings

- default profile: `Garuda.profile`
- menu bar normally hidden
- status bar disabled
- window size remembered

## Apply

```fish
hms
```

Restart Konsole after changing profile/global settings if the live instance does not reload them.
