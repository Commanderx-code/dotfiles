---
title: pkg-owner
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/pkg-owner.fish
runtime: ~/.local/bin/pkg-owner
tags: pkg owner backup recovery home-manager
status: active
criticality: important
last_verified: 2026-08-26
---


# `pkg-owner`

## Purpose

Identify whether a command is supplied by Nix/Home Manager, Pacman, a user-local helper, or an unknown/manual source.

## Usage

```fish
pkg-owner COMMAND
```

Examples:

```fish
pkg-owner fd
pkg-owner grub-mkconfig
pkg-owner backup-personal
```

## Detection Order

1. Resolve the command path with Fish `command -s`.
2. Resolve symlinks with `readlink -f`.
3. If under `/nix/store/`: report **Nix / Home Manager**.
4. Otherwise ask Pacman with `pacman -Qo`.
5. If under `~/.local/`: report user-local/Home Manager helper/manual.
6. Otherwise report unknown/manual.

## Why Use It

This helps decide whether a package belongs in Home Manager or should remain part of system infrastructure.
