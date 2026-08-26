---
title: backup-restic-credential
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-restic-credential.fish
runtime: ~/.local/bin/backup-restic-credential
tags: backup restic credential backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `backup-restic-credential`

## Purpose

Creates a standalone GPG-encrypted copy of the Restic repository password so disaster recovery does not depend on restoring KDE Wallet first.

## Usage

```fish
backup-restic-credential
```

## Credential Source

KDE Wallet:

```text
Wallet: kdewallet
Folder: Restic
Entry: Crucial-X6
```

## Output

```text
/run/media/$USER/Linux-Backup/secrets/restic-password-YYYY-MM-DD_HH-MM-SS.txt.gpg
```

## Encryption

```text
GPG symmetric encryption
AES256
mode 0600
```

The password is piped directly from KWallet into GPG. The script does not intentionally write plaintext to disk and explicitly erases its Fish variable after encryption.

## Recover

```fish
gpg --decrypt /run/media/$USER/Linux-Backup/secrets/restic-password-*.gpg
```

Use a separate recovery passphrase you will remember.

🛑 Do not use the Restic password itself as the GPG passphrase.
