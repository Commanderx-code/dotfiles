---
title: System State Backup
category: Backup
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-system-state.fish
runtime: ~/.local/bin/backup-system-state
tags: backup system-state grub sddm plymouth ufw plasma pacman
status: active
criticality: critical
last_verified: 2026-08-26
---

# System State Backup

## Command

```fish
backup-system-state
```

## Destination

```text
~/dotfiles/system-backup
```

## Captured System Configuration

### SDDM

- `/etc/sddm.conf`
- `/etc/sddm.conf.d`
- `/usr/share/sddm/themes/silent`

### GRUB

- `/etc/default/grub`
- `/usr/share/grub/themes/cachyos`

### Plymouth

- `/etc/plymouth/plymouthd.conf`
- `/usr/share/plymouth/themes/arch-slider-and-glow`

### Firewall

- `/etc/ufw`

### Pacman

- `/etc/pacman.conf`
- `/etc/pacman.d/mirrorlist`
- `/etc/pacman.d/chaotic-mirrorlist`

Files copied with `sudo` are chowned back to the normal user inside the repository.

## Plasma Configuration

Saved from `~/.config`:

```text
kdeglobals
kwinrc
kwinrulesrc
plasmarc
plasma-org.kde.plasma.desktop-appletsrc
kglobalshortcutsrc
kscreenlockerrc
dolphinrc
kiorc
krunnerrc
```

## Plasma Appearance

Saved from `~/.local/share`:

```text
plasma
color-schemes
aurorae
wallpapers
```

Konsole is deliberately excluded because Home Manager manages it.

Icon themes are deliberately excluded because of their large size.

## Inventory Snapshot

Also records:

- explicit Pacman packages
- foreign/AUR packages
- Flatpak apps
- enabled system services
- enabled user services

## Explicitly Not Backed Up Here

```text
~/.ssh
~/.gnupg
KDE Wallet / keyrings
NetworkManager credentials
```

Secrets use the encrypted backup workflow instead.

## Current Review Note

The final size-report command currently redirects stderr to:

```text
/dev/nvidia-modesetl
```

in the live script. That path looks like an accidental typo and is worth correcting separately after review. The Bible does not silently modify the source.
