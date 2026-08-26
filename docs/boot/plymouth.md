---
title: Plymouth
category: Boot
managed_by: System snapshot / manual
source: ~/dotfiles/system-backup/plymouth
runtime: /etc/plymouth/plymouthd.conf + /usr/share/plymouth/themes
tags: plymouth boot splash arch slider glow seamless
status: active
criticality: important
last_verified: 2026-08-26
---

# Plymouth

## Current Theme

```text
arch-slider-and-glow
```

Saved daemon config:

```ini
[Daemon]
Theme=arch-slider-and-glow
```

## Theme Source

```text
~/dotfiles/system-backup/plymouth/arch-slider-and-glow
```

Runtime:

```text
/usr/share/plymouth/themes/arch-slider-and-glow
```

## Theme Design

The theme identifies itself as:

```text
Arch Linux boot animation with slider and small glow animation
```

and uses Plymouth's `two-step` module.

It includes:

- 94 animation frames (`animation-00` through `animation-93`)
- progress frames
- black background
- centered animation/dialog
- Arch-blue progress bar
- boot, shutdown and reboot end animations
- update/upgrade progress handling

## Important Appearance Settings

```text
Transition=none
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
DialogClearsFirmwareBackground=true
MessageBelowAnimation=true
```

## Apply After System-Level Plymouth Changes

Use the distro-appropriate initramfs rebuild. In this setup the recovery tooling prefers:

```fish
sudo dracut-rebuild
```

## Verify

```fish
plymouth-set-default-theme
```

or inspect:

```fish
cat /etc/plymouth/plymouthd.conf
```

## Backup / Restore

```fish
backup-system-state
restore-system
```
