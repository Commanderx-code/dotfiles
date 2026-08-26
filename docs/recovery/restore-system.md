---
title: restore-system
category: Recovery
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/restore-system.fish
runtime: ~/.local/bin/restore-system
tags: restore disaster-recovery grub sddm plymouth ufw pacman plasma
status: active
criticality: critical
last_verified: 2026-08-26
---

# `restore-system`

## Purpose

Interactive restoration of saved workstation configuration after reinstall/recovery.

```fish
restore-system
```

## Safety Design

Before replacing current configuration, the script creates a timestamped pre-restore copy:

```text
~/.local/state/system-restore-pre/YYYY-MM-DD_HH-MM-SS
```

Keep that copy until the recovered machine has booted and been verified.

## What It Refuses To Blindly Restore

The script explicitly avoids treating these as portable:

- old generated `grub.cfg`
- old disk UUID assumptions
- old EFI boot entries
- every saved package automatically
- every saved service automatically

## Distribution Check

The script reads `/etc/os-release`.

It was designed for Garuda Linux. On a non-Garuda system it warns and asks whether to continue.

## Interactive Restore Areas

- Plasma configuration
- SDDM configuration and Silent theme
- Plymouth configuration and `arch-slider-and-glow`
- `/etc/default/grub` and CachyOS GRUB theme assets
- UFW configuration
- Pacman configuration and mirrorlists
- package inventory review
- initramfs rebuild
- GRUB regeneration

## Boot Rebuild

For initramfs it prefers:

```fish
sudo dracut-rebuild
```

and can fall back to:

```fish
sudo dracut --regenerate-all --force
```

GRUB regeneration uses available tooling such as:

```fish
sudo update-grub
```

or:

```fish
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

🛑 Do not manually copy an old generated `grub.cfg` onto a new installation.

## Post-Restore Checks

```fish
systemctl --failed
systemctl --user --failed
sudo ufw status verbose
home-manager generations
```
