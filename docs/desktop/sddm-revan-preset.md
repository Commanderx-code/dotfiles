---
title: SilentSDDM Revan Preset
category: Desktop
managed_by: System theme
source: ~/dotfiles/system-backup/sddm/silent/configs/revan.conf
runtime: /usr/share/sddm/themes/silent/configs/revan.conf
tags: sddm revan star-wars theme login
status: active
criticality: normal
last_verified: 2026-08-26
---

# SilentSDDM Revan Preset

## Backgrounds

Lock screen:

```text
revan.jpg
```

Login screen:

```text
revan.mp4
```

Animated placeholder:

```text
revan.jpg
```

## Login Layout

```text
position = left
margin = 120
```

## Avatar

```text
shape = circle
active-size = 120
inactive-size = 80
```

## Password Field

```text
width = 150
height = 30
background = white
content = black
masked character = ●
```

The password field and login button form a joined rounded control.

## Clock

```text
position = center-left
format = h:mm AP
font = RedHatDisplay
size = 120
weight = 900
```

## Date

```text
format = dddd, MMMM dd, yyyy
locale = en_US
```

## Menus

Session, keyboard layout and power menus are configured along the center-left side.

The on-screen keyboard button itself is disabled in this preset.

## Modify

Edit the source/snapshot only if you intend to preserve that change in the repository. For live experimentation, carefully edit the runtime preset and then refresh the backed-up system state once satisfied.
