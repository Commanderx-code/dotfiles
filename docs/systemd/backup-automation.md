---
title: Backup Automation
category: Systemd
managed_by: Home Manager
source: ~/dotfiles/home-manager/modules/backup-automation.nix
runtime: systemd --user
tags: systemd backup restic timer path
status: active
criticality: critical
last_verified: 2026-08-26
---

# Backup Automation

## On-Mount Backup

User path unit:

```text
backup-on-mount.path
```

Watches:

```text
/run/media/commander
```

and triggers:

```text
backup-on-mount.service
```

Service command:

```text
~/.local/bin/backup-on-mount
```

## Weekly Maintenance

Timer:

```text
restic-maintenance.timer
```

Schedule:

```text
weekly
Persistent=true
RandomizedDelaySec=30m
```

## Monthly Deep Check

Timer:

```text
restic-deep-check.timer
```

Schedule:

```text
monthly
Persistent=true
RandomizedDelaySec=1h
```

## Useful Commands

```fish
systemctl --user status backup-on-mount.path
systemctl --user status backup-on-mount.service
systemctl --user status restic-maintenance.timer
systemctl --user status restic-deep-check.timer
systemctl --user list-timers
```

Logs:

```fish
journalctl --user -u backup-on-mount.service
journalctl --user -u restic-maintenance.service
journalctl --user -u restic-deep-check.service
```

## Home Manager Source

```text
~/dotfiles/home-manager/modules/backup-automation.nix
```
