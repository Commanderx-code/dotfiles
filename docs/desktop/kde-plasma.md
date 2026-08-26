---
title: KDE Plasma Desktop
category: Desktop
managed_by: System snapshot / KDE
source: ~/dotfiles/system-backup/plasma
runtime: ~/.config + ~/.local/share
tags: kde plasma sweet tokyo-night kwin desktop
status: active
criticality: important
last_verified: 2026-08-26
---

# KDE Plasma Desktop

## Overview

The desktop state is backed up under:

```text
~/dotfiles/system-backup/plasma
```

This is a snapshot/reference layer rather than a complete declarative KDE setup.

## Key Runtime Files

```text
~/.config/kdeglobals
~/.config/kwinrc
~/.config/plasmarc
~/.config/plasma-org.kde.plasma.desktop-appletsrc
~/.config/kscreenlockerrc
```

## Current Look

From the saved state:

- KDE color scheme: `Sweet`
- Plasma theme: `Sweet`
- KWin decoration: `Sweet-Dark`
- icon theme: `Gradient-Dark-Icons`
- fixed-width font: `FiraCode Nerd Font Mono`
- UI font: `Fira Sans`
- accent color: `61,174,233`

## KWin Effects

Saved `kwinrc` enables:

- Better Blur DX
- Cover Switch
- desktop-change OSD
- fade
- Flip Switch
- Magic Lamp
- wobbly windows

Round-corner configuration is also present with a 20px radius.

## Desktop Layout

The Plasma applet layout records a 1920×1080 desktop and includes a custom Modern Clock plasmoid.

The application launcher uses:

```text
/usr/share/pixmaps/archlinux-logo.png
```

as its icon.

## Backed-Up Appearance Assets

The snapshot also preserves user-local:

```text
~/.local/share/plasma
~/.local/share/color-schemes
~/.local/share/aurorae
~/.local/share/wallpapers
```

including Tokyo Night Plasma assets and the custom Modern Clock plasmoid.

## Apply / Restore

Use the system-state recovery workflow:

```fish
restore-system
```

Plasma restoration is interactive.

## Caution

KDE config files can contain monitor IDs, applet IDs, wallpaper paths, and layout state that are machine-specific. Review before manually copying them onto a different display/layout.
