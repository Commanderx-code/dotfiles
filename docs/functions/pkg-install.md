---
title: pkg-install
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/pkg-install.fish
runtime: ~/.local/bin/pkg-install
tags: pkg install backup recovery home-manager
status: active
criticality: important
last_verified: 2026-08-26
---


# `pkg-install`

## Purpose

Interactive helper for deciding whether a package should be managed by Home Manager or Pacman.

## Usage

```fish
pkg-install PACKAGE
```

## Choices

### 1 — Home Manager

Intended for personal CLI/user applications.

The helper opens:

```text
~/dotfiles/home-manager/modules/packages.nix
```

and asks you to add the package inside `home.packages`.

After editing:

```fish
hm-rebuild
```

### 2 — Pacman

Intended for:

- kernels
- drivers
- KDE/system desktop components
- networking
- security
- boot
- filesystem
- hardware/system infrastructure

Installs with:

```fish
sudo pacman -S --needed PACKAGE
```

### 3 — Cancel
