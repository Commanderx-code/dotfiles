---
title: Home Manager Helper Commands
category: System
managed_by: Home Manager
source: ~/dotfiles/home-manager/home.nix
runtime: ~/.local/bin
tags: home-manager scripts helpers
status: active
criticality: important
last_verified: 2026-08-26
---

# Home Manager Helper Commands

`home.nix` installs these source scripts as executable files under `~/.local/bin`:

```text
backup-sddm
restore-sddm
backup-system-state
backup-secrets
backup-personal
backup-everything
backup-restic-credential
restore-system
pkg-owner
pkg-install
hm-rebuild
backup-app-inventory
restore-apps
```

The backup automation module additionally installs:

```text
backup-on-mount
restic-maintenance
restic-deep-check
```

## Source of Truth

```text
~/dotfiles/home-manager/scripts/
```

## Runtime

```text
~/.local/bin/
```

Do not edit the Home Manager-generated runtime copy. Edit the source in the repository and rebuild:

```fish
hm-rebuild
```

For brand-new files in the Git-backed flake:

```fish
git add path/to/new/file
hm-rebuild
```
