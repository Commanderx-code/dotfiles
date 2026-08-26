---
title: Desktop and Boot Troubleshooting
category: Troubleshooting
managed_by: Documentation
source: ~/dotfiles/system-backup
runtime:
tags: grub plymouth sddm kde konsole troubleshooting
status: active
criticality: important
last_verified: 2026-08-26
---

# Desktop and Boot Troubleshooting

## GRUB Theme Missing

Check:

```fish
grep -E 'GRUB_(THEME|BACKGROUND|GFXMODE|GFXPAYLOAD)' /etc/default/grub
```

Expected saved theme:

```text
/usr/share/grub/themes/cachyos/theme.txt
```

Then regenerate GRUB if source configuration changed.

## GRUB Resolution

Saved target:

```text
1920x1080
```

Check supported modes in the GRUB console with:

```text
videoinfo
```

## Plymouth Theme Missing

Check:

```fish
cat /etc/plymouth/plymouthd.conf
```

Expected:

```text
Theme=arch-slider-and-glow
```

Verify the theme directory exists under `/usr/share/plymouth/themes/` and rebuild initramfs after system-level changes.

## SDDM Theme Not Loading

Check:

```fish
cat /etc/sddm.conf.d/kde_settings.conf
```

Expected theme:

```text
Current=silent
```

Also verify:

```text
/usr/share/sddm/themes/silent
```

exists.

## Num Lock Not Enabled at Login

Check:

```fish
cat /etc/sddm.conf.d/10-numlock.conf
```

Expected:

```ini
[General]
Numlock=on
```

## Konsole Changes Missing

Run:

```fish
hms
```

Then verify:

```fish
ls -l ~/.config/konsolerc
ls -l ~/.local/share/konsole/Garuda.profile
ls -l ~/.local/share/konsole/Sweet.colorscheme
```

## KDE Restore Caution

Do not assume old monitor/applet IDs are portable. Plasma layout files can carry hardware/layout-specific state.
