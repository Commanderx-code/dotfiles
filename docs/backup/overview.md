---
title: Backup System Overview
category: Backup
managed_by: Home Manager / Restic / GPG
source: ~/dotfiles/home-manager/scripts
runtime: ~/.local/bin
tags: backup restic gpg disaster-recovery linux-backup
status: active
criticality: critical
last_verified: 2026-08-26
---

# Backup System Overview

## Purpose

This workstation uses several backup layers instead of treating Git as a complete backup.

| Layer | Protects |
|---|---|
| Git + dotfiles | tracked configuration, Home Manager, recovery scripts |
| `system-backup/` | system and desktop configuration snapshots |
| Restic | personal files, projects, applications, dotfiles, Cargo state |
| GPG archives | SSH keys, KDE Wallet, standalone Restic credential |
| inventories | Pacman, AUR/foreign, Flatpak, AppImage, service state |
| LUKS | encryption of the external `Linux-Backup` drive |

## Backup Drive

Expected mount point:

```text
/run/media/commander/Linux-Backup
```

Restic repository:

```text
/run/media/commander/Linux-Backup/restic
```

Encrypted secrets:

```text
/run/media/commander/Linux-Backup/secrets
```

## Normal Workflows

### Quick personal backup

```fish
backup-personal
```

### Full manual backup

```fish
backup-everything
```

### Weekly repository maintenance

```fish
restic-maintenance
```

### Monthly deeper integrity check

```fish
restic-deep-check
```

## Full Backup Order

`backup-everything` runs:

1. `backup-system-state`
2. `backup-app-inventory`
3. `backup-personal`
4. `backup-secrets`
5. `backup-restic-credential`

Git changes are deliberately **not** committed or pushed automatically.

## Important Rules

🛑 Never commit:

- private SSH keys
- decrypted KDE Wallet data
- plaintext Restic passwords
- NetworkManager credential files
- decrypted secret archives

✅ Before destructive disk work:

```fish
backup-everything
```

Then verify repository access and review `git status`.
