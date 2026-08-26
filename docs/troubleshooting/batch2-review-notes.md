---
title: Backup and Recovery Review Notes
category: Troubleshooting
managed_by: Documentation
source: ~/dotfiles/home-manager/scripts
runtime:
tags: review backup bugs maintenance
status: active
criticality: important
last_verified: 2026-08-26
---

# Backup and Recovery Review Notes

These are observations from the live Batch 2 source. They are documented rather than silently changed.

## `backup-system-state`: suspicious stderr target

The script currently contains:

```fish
du -sh "$BACKUP"/* 2>/dev/nvidia-modesetl
```

`/dev/nvidia-modesetl` looks like a typo rather than a normal stderr sink. The conventional discard target is `/dev/null`.

Review the live script before changing it.

## Two SDDM Backup Models Exist

There are intentionally different locations/workflows:

```text
~/dotfiles/sddm
```

used by dedicated `backup-sddm` / `restore-sddm`, and:

```text
~/dotfiles/system-backup/sddm
```

used by the broader `backup-system-state` / `restore-system` workflow.

Documenting this distinction avoids restoring from the wrong tree.

## Restic Maintenance Lock Scope

`restic-maintenance` protects the `forget --prune` step with its own lock. Its later standard `restic check` is not wrapped in that same `flock` invocation.

This is simply the current behavior; if concurrent Restic activity becomes an issue, review the lock strategy.

## Restore Inventories Are Historical, Not Authoritative

`restore-apps` correctly warns that package inventories can contain obsolete kernels, drivers, old Garuda packages, renamed packages, or hardware-specific packages.

Treat them as reconstruction aids, not a blindly executable desired-state manifest.
