---
title: KDE Wallet
category: Security
managed_by: KDE
source: ~/.local/share/kwalletd
runtime: ~/.local/share/kwalletd
tags: kwallet credentials ssh restic secrets
status: active
criticality: critical
last_verified: 2026-08-26
---

# KDE Wallet

## Purpose

KDE Wallet is used as a local credential store.

Current workflows depend on it for:

- Restic repository password retrieval
- graphical SSH passphrase prompting through KDE tooling

## Restic Credential

The backup scripts query:

```text
Wallet: kdewallet
Folder: Restic
Entry: Crucial-X6
```

Command:

```fish
kwallet-query -f Restic -r Crucial-X6 kdewallet
```

## Wallet Files

Runtime location:

```text
~/.local/share/kwalletd
```

These files are secret and are not stored in the public dotfiles repository.

## Encrypted Backup

`backup-secrets` creates:

```text
kwallet-YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

using AES-256 symmetric GPG encryption.

## Recovery

Restore/decrypt into a temporary location first. Verify the archive before replacing live wallet state.

Expected final location:

```text
~/.local/share/kwalletd
```

## Caution

🛑 Never commit decrypted wallet files.

Also keep the GPG recovery passphrase independently available; relying only on a credential stored inside the wallet creates a recovery dependency loop.
