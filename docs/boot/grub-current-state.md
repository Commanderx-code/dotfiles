---
title: GRUB Current Saved State
category: Boot
managed_by: System snapshot
source: ~/dotfiles/system-backup/grub
runtime: /etc/default/grub
tags: grub boot cachyos theme garuda
status: active
criticality: critical
last_verified: 2026-08-26
---

# GRUB Current Saved State

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

## Important Saved Settings

```text
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR='Garuda'
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_OS_PROBER=false
GRUB_THEME="/usr/share/grub/themes/cachyos/theme.txt"
GRUB_BACKGROUND="/usr/share/grub/themes/cachyos/background.png"
```

Kernel command line includes quiet/splash behavior and Linux security module settings including AppArmor.

## Recovery Rule

The backup stores **source configuration and theme assets**, not a generated boot menu to transplant.

🛑 Never blindly restore an old:

```text
/boot/grub/grub.cfg
```

onto a fresh installation.

Restore `/etc/default/grub` as appropriate, then generate a fresh menu for the current disks/filesystems.
