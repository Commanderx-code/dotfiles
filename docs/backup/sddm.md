---
title: SDDM Backup and Restore
category: Backup
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/backup-sddm.sh
runtime: ~/.local/bin/backup-sddm
tags: sddm silent theme backup restore
status: active
criticality: important
last_verified: 2026-08-26
---

# SDDM Backup and Restore

## Dedicated Backup

```fish
backup-sddm
```

Source theme:

```text
/usr/share/sddm/themes/silent
```

Repository destination:

```text
~/dotfiles/sddm
```

The dedicated helper copies:

- theme presets/configs
- backgrounds
- customized `BatteryIndicator.qml`
- customized `LoginScreen.qml`
- `metadata.desktop`
- `/etc/sddm.conf.d`
- `/etc/sddm.conf` when present and non-empty

## Dedicated Restore

```fish
restore-sddm
```

The Silent theme must already be installed at:

```text
/usr/share/sddm/themes/silent
```

The helper uses `sudo install` with mode `0644` for restored files and `0755` for required directories.

After restoring, it reports the current display-manager symlink and recommends rebooting.

## Relationship to `backup-system-state`

The general system-state snapshot also backs up SDDM and the Silent theme under:

```text
~/dotfiles/system-backup/sddm
```

The dedicated `backup-sddm` workflow instead targets the separate:

```text
~/dotfiles/sddm
```

tree containing the explicitly customized SilentSDDM files.
