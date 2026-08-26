---
title: GRUB
category: Boot
managed_by: System snapshot / manual
source: ~/dotfiles/system-backup/grub
runtime: /etc/default/grub + /usr/share/grub/themes/cachyos
tags: grub boot theme cachyos garuda arch recovery
status: active
criticality: critical
last_verified: 2026-08-26
---

# GRUB

## Saved Source

```text
~/dotfiles/system-backup/grub/grub
```

represents the backed-up `/etc/default/grub`.

Theme assets:

```text
~/dotfiles/system-backup/grub/cachyos
```

Runtime theme:

```text
/usr/share/grub/themes/cachyos/theme.txt
```

## Current Saved Settings

```text
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR='Garuda'
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_OS_PROBER=false
GRUB_THEME=/usr/share/grub/themes/cachyos/theme.txt
GRUB_BACKGROUND=/usr/share/grub/themes/cachyos/background.png
```

The kernel command line includes quiet/splash boot and LSMs including AppArmor.

## Theme History

The current theme is based on the CachyOS GRUB theme and has been used with customized Arch/Garuda branding.

## Regenerate

On this Garuda/Arch-style setup:

```fish
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Resolution

The saved graphical mode is:

```text
1920x1080
```

with:

```text
GRUB_GFXPAYLOAD_LINUX=keep
```

to help maintain resolution into early boot.

## Recovery Rule

🛑 Never restore an old generated:

```text
/boot/grub/grub.cfg
```

onto a different installation/disk layout.

Restore source configuration/theme assets as appropriate and regenerate the menu for the current system.

## Backup / Restore

```fish
backup-system-state
restore-system
```
