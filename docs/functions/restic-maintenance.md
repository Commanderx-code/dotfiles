---
title: restic-maintenance
category: Function
managed_by: Home Manager + systemd user
source: ~/dotfiles/home-manager/scripts/restic-maintenance.fish
runtime: ~/.local/bin/restic-maintenance
tags: restic maintenance backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `restic-maintenance`

## Purpose

Applies the Restic retention policy, prunes unused data, and runs a standard repository check.

## Usage

```fish
restic-maintenance
```

## Retention Policy

```text
7 daily
5 weekly
12 monthly
3 yearly
```

Equivalent Restic policy:

```text
--keep-daily 7
--keep-weekly 5
--keep-monthly 12
--keep-yearly 3
--prune
```

## Safety / Concurrency

Uses:

```text
$XDG_RUNTIME_DIR/restic-maintenance.lock
```

with non-blocking `flock`.

If the drive or repository is absent, the script exits successfully without doing maintenance.

## Automation

Home Manager schedules this with:

```text
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=30m
```

Check:

```fish
systemctl --user status restic-maintenance.timer
systemctl --user list-timers restic-maintenance.timer
```
