---
title: backup-app-inventory
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-app-inventory.fish
runtime: ~/.local/bin/backup-app-inventory
tags: backup app inventory backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `backup-app-inventory`

## Purpose

Captures application/package inventory information needed for reconstruction after a reinstall.

## Usage

```fish
backup-app-inventory
```

## Output Directory

```text
~/dotfiles/system-backup/inventories
```

## Pacman Files

```text
pacman-native-explicit.txt
pacman-foreign-explicit.txt
pacman-all.txt
```

Generated with:

```fish
pacman -Qqen
pacman -Qqem
pacman -Q
```

## Flatpak Files

```text
flatpak-apps.tsv
flatpak-runtimes.tsv
flatpak-remotes.tsv
```

These preserve application IDs, origins/remotes, installation scope, runtime information, and remote URLs/options.

## AppImages

Searches:

```text
~/Applications
~/Downloads
```

using GNU `/usr/bin/find`, specifically avoiding the interactive Fish `find -> fd` override.

Result:

```text
appimages.txt
```

## Important Distinction

This inventory records **what was installed**. It is not a package backup.

AppImages under `~/Applications` are physically preserved by `backup-personal`.
