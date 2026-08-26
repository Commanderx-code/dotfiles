---
title: backup-personal
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-personal.fish
runtime: ~/.local/bin/backup-personal
tags: backup personal backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `backup-personal`

## Purpose

Runs the normal Restic backup of personal data and immediately checks the repository.

## Usage

```fish
backup-personal
```

## Repository

```text
/run/media/$USER/Linux-Backup/restic
```

Authentication is read from KDE Wallet with:

```text
kwallet-query -f Restic -r Crucial-X6 kdewallet
```

## Backed-Up Paths

The script includes existing paths from:

```text
~/Documents
~/Desktop
~/Downloads
~/Pictures
~/Videos
~/Music
~/Projects
~/Applications
~/dotfiles
~/.cargo
```

Missing paths are skipped.

## Workflow

1. Verify `restic` exists.
2. Verify `kwallet-query` exists.
3. Verify the Restic repository directory exists.
4. Build a list of backup paths that currently exist.
5. Run `restic backup`.
6. Run `restic check`.
7. Show the latest five snapshots.

## Verification

```fish
restic \
  --repo "/run/media/$USER/Linux-Backup/restic" \
  --password-command "kwallet-query -f Restic -r Crucial-X6 kdewallet" \
  snapshots --latest 5
```

## Failure Conditions

The command exits non-zero if:

- Restic is missing.
- `kwallet-query` is missing.
- `Linux-Backup` is not unlocked/mounted.
- no configured backup path exists.
- backup, repository check, or snapshot listing fails.
