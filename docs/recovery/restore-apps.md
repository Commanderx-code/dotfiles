---
title: restore-apps
category: Recovery
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/restore-apps.fish
runtime: ~/.local/bin/restore-apps
tags: restore pacman aur flatpak appimage packages
status: active
criticality: important
last_verified: 2026-08-26
---

# `restore-apps`

## Purpose

Interactive helper for reconstructing applications from the saved inventories.

```fish
restore-apps
```

## Inventory Source

```text
~/dotfiles/system-backup/inventories
```

## Pacman

Reads:

```text
pacman-native-explicit.txt
```

and optionally runs:

```fish
sudo pacman -S --needed - < pacman-native-explicit.txt
```

⚠️ The script warns that this list may include old kernels, drivers, Garuda packages, and hardware-specific packages.

## Foreign / AUR

Reads:

```text
pacman-foreign-explicit.txt
```

Prefers `paru`, falls back to `yay`, and installs with `--needed`.

## Flatpak

Can restore:

- missing remotes
- user/system installation scope
- applications and their original remotes

## AppImages

AppImages themselves are restored by Restic.

The helper reads `appimages.txt` and reports each path as `OK` or `MISSING`.

## Home Manager

Home Manager packages are intentionally separate:

```fish
hm-rebuild
```

## Recommended Final Checks

```fish
pacman -Qqe
flatpak list --app
hm-rebuild
```

Review failed/renamed packages rather than forcing incompatible packages.
