---
title: backup-everything
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-everything.fish
runtime: ~/.local/bin/backup-everything
tags: backup everything backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `backup-everything`

## Purpose

Runs the complete manual workstation backup workflow.

## Usage

```fish
backup-everything
```

## Preconditions

The external drive must be mounted at:

```text
/run/media/$USER/Linux-Backup
```

## Exact Order

1. `backup-system-state`
2. `backup-app-inventory`
3. `backup-personal`
4. `backup-secrets /run/media/$USER/Linux-Backup/secrets`
5. `backup-restic-credential`

The workflow stops immediately if any stage fails.

## Result Locations

System snapshot:

```text
~/dotfiles/system-backup
```

Personal Restic repository:

```text
/run/media/$USER/Linux-Backup/restic
```

Encrypted secrets:

```text
/run/media/$USER/Linux-Backup/secrets
```

## Git Behavior

The command prints:

```fish
git -C "$HOME/dotfiles" status --short
```

but does **not** commit or push anything.

After a successful backup:

```fish
cd ~/dotfiles
git status
```

Review system-state changes and commit only when appropriate.
