---
title: backup-on-mount
category: Function
managed_by: Home Manager + systemd user
source: ~/dotfiles/home-manager/scripts/backup-on-mount.fish
runtime: ~/.local/bin/backup-on-mount
tags: backup on mount backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `backup-on-mount`

## Purpose

Automatically runs a personal Restic backup after `Linux-Backup` is unlocked and mounted.

## Trigger

Home Manager creates a user systemd path unit watching:

```text
/run/media/commander
```

A change triggers:

```text
backup-on-mount.service
```

which executes:

```text
~/.local/bin/backup-on-mount
```

## Mount Detection

The script waits up to roughly 30 seconds:

```text
15 attempts × 2 seconds
```

for both:

```text
/run/media/$USER/Linux-Backup
/run/media/$USER/Linux-Backup/restic
```

to become available.

## Duplicate Protection

A runtime stamp suppresses duplicate triggers for five minutes:

```text
$XDG_RUNTIME_DIR/backup-on-mount.stamp
```

## Concurrency Protection

A `flock` lock prevents simultaneous personal backups:

```text
$XDG_RUNTIME_DIR/backup-personal.lock
```

## Status

```fish
systemctl --user status backup-on-mount.path
systemctl --user status backup-on-mount.service
```

Recent log:

```fish
journalctl --user -u backup-on-mount.service --since "10 minutes ago"
```
