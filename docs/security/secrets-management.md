---
title: Secrets Management
category: Security
managed_by: KDE Wallet + GPG + manual policy
source: ~/dotfiles/home-manager/scripts/backup-secrets.fish
runtime:
tags: secrets ssh kwallet gpg restic git
status: active
criticality: critical
last_verified: 2026-08-26
---

# Secrets Management

## Principle

The public dotfiles repository contains configuration and recovery tooling, not plaintext credentials.

## Never Commit

```text
private SSH keys
KDE Wallet files
plaintext Restic passwords
decrypted .gpg archives
NetworkManager connection credentials
```

## Secret Locations

SSH:

```text
~/.ssh
```

KDE Wallet:

```text
~/.local/share/kwalletd
```

Restic password:

```text
KDE Wallet -> Restic -> Crucial-X6
```

Encrypted external backups:

```text
/run/media/$USER/Linux-Backup/secrets
```

## Backup Commands

SSH + KDE Wallet:

```fish
backup-secrets /run/media/$USER/Linux-Backup/secrets
```

Standalone Restic recovery credential:

```fish
backup-restic-credential
```

## Why Both KWallet and GPG Exist

KWallet is the convenient day-to-day credential store.

GPG archives are the disaster-recovery layer when the live wallet is unavailable.

That separation prevents Restic recovery from depending entirely on a functioning KDE Wallet restore.
