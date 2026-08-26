---
title: Start Here
category: Index
managed_by: Documentation
source: ~/dotfiles/docs
runtime:
tags: index start here bible commander
status: active
criticality: critical
last_verified: 2026-08-26
---

# Commander Config Bible — Start Here

This repository is the operational reference for the workstation, dotfiles, recovery system,
security configuration, networking plans, and homelab.

The guiding questions are:

> What is this?
>
> Where is the real config?
>
> How do I use it?
>
> How do I change it?
>
> How do I verify it?
>
> How do I recover it if it breaks?
>
> Why is it configured this way?

## Main Entry Point

```fish
config-index
```

Examples:

```fish
config-index fish
config-index neovim
config-index backup
config-index grub
config-index ssh
config-index docker
config-index restore
```

## System Map

```text
WORKSTATION
├── Home Manager
│   ├── Fish
│   ├── Neovim
│   ├── Starship
│   ├── Fastfetch
│   ├── Konsole
│   └── Topgrade
│
├── System Configuration
│   ├── GRUB
│   ├── Plymouth
│   ├── SDDM
│   ├── KDE Plasma
│   ├── UFW
│   └── AppArmor
│
├── Security
│   ├── SSH agent
│   ├── KDE Wallet
│   ├── GPG
│   └── secret backup
│
├── Backup / Recovery
│   ├── Restic
│   ├── system-state snapshot
│   ├── application inventory
│   ├── encrypted secrets
│   └── disaster recovery
│
└── Homelab
    └── ZimaBoard
        ├── Docker
        ├── Dockge
        ├── Tugtainer
        ├── Home Assistant
        ├── Zigbee2MQTT
        ├── Mosquitto
        ├── Homepage
        ├── Uptime Kuma
        ├── Tailscale
        ├── AdGuard Home
        └── Unbound
```

## Source-of-Truth Rules

### User Configuration

Primary source:

```text
~/dotfiles
```

Home Manager source:

```text
~/dotfiles/home-manager
```

Runtime-generated files should generally not be edited directly.

### System Snapshots

```text
~/dotfiles/system-backup
```

These are recovery/reference snapshots, not always declarative desired state.

### Homelab

Compose definitions:

```text
/DATA/compose
```

Persistent state:

```text
/DATA/AppData
```

CasaOS/ZimaOS definitions:

```text
/var/lib/casaos/apps
```

## Important Commands

| Goal | Command |
|---|---|
| Search the Bible | `config-index` |
| Apply Home Manager | `hms` |
| Safe HM build + switch | `hm-rebuild` |
| Full workstation update | `full-upgrade` |
| Full update including VCS/AUR devel | `full-upgrade-devel` |
| Normal personal backup | `backup-personal` |
| Full manual backup | `backup-everything` |
| Restore workstation state | `restore-system` |
| Restore/review applications | `restore-apps` |
| Find who owns a command | `pkg-owner COMMAND` |
| Decide HM vs Pacman | `pkg-install PACKAGE` |
| Show Fish shortcuts | `helpme` |

## Before Risky System Work

Run:

```fish
backup-everything
```

Then verify:

```fish
git status
```

and confirm the external backup drive and Restic repository are accessible.

## Before Editing a Config

1. Search the Bible.
2. Identify the source-of-truth path.
3. Back up if the component is critical.
4. Edit the source file, not a generated symlink.
5. Rebuild/reload.
6. Verify.
7. Update the Bible if behavior changed.

## Critical Recovery Pages

Search:

```fish
config-index "disaster recovery"
config-index restore-system
config-index restic
config-index grub
config-index secrets
config-index zimaboard
```
