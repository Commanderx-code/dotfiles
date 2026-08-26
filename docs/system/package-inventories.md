---
title: Package and Application Inventories
category: System
managed_by: backup-app-inventory / backup-system-state
source: ~/dotfiles/system-backup/inventories
runtime:
tags: pacman aur flatpak appimage services inventory
status: active
criticality: important
last_verified: 2026-08-26
---

# Package and Application Inventories

## Current Inventory Files

```text
pacman-native-explicit.txt
pacman-foreign-explicit.txt
pacman-all.txt
pacman-explicit.txt
aur-foreign.txt
flatpak-apps.tsv
flatpak-runtimes.tsv
flatpak-remotes.tsv
flatpaks.txt
appimages.txt
enabled-system-services.txt
enabled-user-services.txt
```

## Meaning

`pacman-native-explicit.txt`
: explicitly installed packages from configured repositories.

`pacman-foreign-explicit.txt`
: explicitly installed foreign packages, typically AUR/manual Pacman packages.

`pacman-all.txt`
: full installed package + version reference.

`flatpak-apps.tsv`
: application ID, origin, and installation scope.

`flatpak-runtimes.tsv`
: runtime ID, branch, origin, scope.

`flatpak-remotes.tsv`
: remote name, URL, options.

`appimages.txt`
: discovered AppImage paths under `~/Applications` and `~/Downloads`.

`enabled-system-services.txt`
: enabled system unit files.

`enabled-user-services.txt`
: enabled user unit files.

## Recovery Philosophy

Do not blindly reinstall every entry.

Home Manager should reconstruct user-level packages already declared there. Pacman inventories are especially useful for reviewing system infrastructure, drivers, kernels, hardware support, security tooling, and desktop components.
