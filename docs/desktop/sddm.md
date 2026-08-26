---
title: SDDM / SilentSDDM
category: Desktop
managed_by: System snapshot + dedicated backup
source: ~/dotfiles/system-backup/sddm
runtime: /etc/sddm.conf.d + /usr/share/sddm/themes/silent
tags: sddm silent revan login numlock kde
status: active
criticality: important
last_verified: 2026-08-26
---

# SDDM / SilentSDDM

## Active Theme

```text
silent
```

The saved KDE SDDM settings contain:

```ini
[Theme]
Current=silent
```

## Num Lock

Num Lock is enabled at the display manager:

```ini
[General]
Numlock=on
```

This is preserved in:

```text
/etc/sddm.conf.d/10-numlock.conf
```

and also appears in the saved KDE settings file.

## Virtual Keyboard / Theme Environment

`20-silent.conf` configures:

```text
InputMethod=qtvirtualkeyboard
```

and the QML import/environment variables needed by SilentSDDM.

## Revan Preset

Saved preset:

```text
/usr/share/sddm/themes/silent/configs/revan.conf
```

Important settings:

- lock screen background: `revan.jpg`
- login background: `revan.mp4`
- login area: left
- login margin: 120
- circular avatar
- white password field
- red login-arrow content
- power/layout/session menus positioned center-left
- clock positioned center-left
- lock-screen blur: 32
- lock-screen image desaturated and darkened

## Media Assets

The saved theme includes multiple backgrounds/presets including:

- Revan
- Star Wars
- Ken
- Rei
- Silvia

## Two Backup Paths

Dedicated customized-theme backup:

```text
~/dotfiles/sddm
```

Broader system snapshot:

```text
~/dotfiles/system-backup/sddm
```

See:

```fish
config-index sddm
```

for the dedicated backup/restore page.

## Restore

Dedicated theme restore:

```fish
restore-sddm
```

Full system-state restore:

```fish
restore-system
```

## Caution

The full SilentSDDM tree contains upstream theme files plus local customizations. Prefer the documented backup/restore helpers instead of manually copying random individual QML files.
