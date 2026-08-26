---
title: backup-secrets
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-secrets.fish
runtime: ~/.local/bin/backup-secrets
tags: backup secrets backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `backup-secrets`

## Purpose

Creates encrypted backups of SSH and KDE Wallet without placing plaintext secrets in the dotfiles repository.

## Usage

```fish
backup-secrets /path/to/backup/folder
```

Normal destination:

```fish
backup-secrets "/run/media/$USER/Linux-Backup/secrets"
```

## Security

The script starts with:

```fish
umask 077
```

and creates GPG symmetric AES-256 encrypted archives.

## SSH Archive

If `~/.ssh` exists:

```text
ssh-YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

Pipeline:

```text
tar -> gpg --symmetric --cipher-algo AES256
```

## KDE Wallet Archive

If `~/.local/share/kwalletd` exists:

```text
kwallet-YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

## Permissions

Successful encrypted archives are set to:

```text
0600
```

## Recovery Requirement

The GPG recovery passphrase must be known independently of the backup drive.

🛑 Do not use the Restic password itself as your only GPG recovery knowledge.
