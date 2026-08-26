---
title: restic-deep-check
category: Function
managed_by: Home Manager + systemd user
source: ~/dotfiles/home-manager/scripts/restic-deep-check.fish
runtime: ~/.local/bin/restic-deep-check
tags: restic deep check backup recovery home-manager
status: active
criticality: critical
last_verified: 2026-08-26
---


# `restic-deep-check`

## Purpose

Performs a deeper Restic integrity check that reads 10% of stored repository data.

## Usage

```fish
restic-deep-check
```

Core operation:

```text
restic check --read-data-subset=10%
```

## Concurrency

Lock:

```text
$XDG_RUNTIME_DIR/restic-deep-check.lock
```

## Automation

Home Manager schedules:

```text
OnCalendar=monthly
Persistent=true
RandomizedDelaySec=1h
```

Check:

```fish
systemctl --user status restic-deep-check.timer
systemctl --user list-timers restic-deep-check.timer
```

## Difference from Standard Maintenance

`restic-maintenance` checks repository structures after pruning.

`restic-deep-check` additionally reads a subset of backup data, making it a more expensive integrity test.
