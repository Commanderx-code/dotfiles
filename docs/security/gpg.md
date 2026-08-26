---
title: GPG Secret Backup Encryption
category: Security
managed_by: GnuPG
source: ~/dotfiles/home-manager/scripts/backup-secrets.fish
runtime: ~/.gnupg
tags: gpg gnupg aes256 backup encryption
status: active
criticality: critical
last_verified: 2026-08-26
---

# GPG Secret Backup Encryption

## Purpose

GPG symmetric encryption protects secret backups stored on the external backup drive.

## Cipher

The backup scripts explicitly use:

```text
AES256
```

with:

```fish
gpg --symmetric --cipher-algo AES256
```

## Files Protected

Examples:

```text
ssh-*.tar.gz.gpg
kwallet-*.tar.gz.gpg
restic-password-*.txt.gpg
```

## Permissions

Encrypted outputs are set to:

```text
0600
```

and `backup-secrets` starts with:

```text
umask 077
```

## Test Decryption

Before depending on an archive:

```fish
gpg --decrypt /path/to/archive.gpg >/dev/null
```

For a Restic credential:

```fish
gpg --decrypt /run/media/$USER/Linux-Backup/secrets/restic-password-*.gpg
```

## Recovery Rule

Keep the GPG passphrase somewhere independent of:

- the workstation
- KDE Wallet
- the Restic repository password

The Restic credential script explicitly warns not to reuse the Restic password as the GPG recovery passphrase.
