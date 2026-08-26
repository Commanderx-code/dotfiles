---
title: What Command Should I Use?
category: Commands
managed_by: Documentation
source: ~/dotfiles/docs
runtime:
tags: commands reference backup restore packages home-manager
status: active
criticality: important
last_verified: 2026-08-26
---

# What Command Should I Use?

| Goal | Command |
|---|---|
| Back up my normal personal data | `backup-personal` |
| Back up everything before risky work | `backup-everything` |
| Refresh system configuration snapshot | `backup-system-state` |
| Refresh package/application inventories | `backup-app-inventory` |
| Back up SSH + KDE Wallet securely | `backup-secrets DESTINATION` |
| Make standalone encrypted Restic credential | `backup-restic-credential` |
| Run repository retention/prune/check | `restic-maintenance` |
| Perform deeper Restic integrity test | `restic-deep-check` |
| Restore workstation configuration | `restore-system` |
| Restore/review installed applications | `restore-apps` |
| Back up only custom SilentSDDM state | `backup-sddm` |
| Restore custom SilentSDDM state | `restore-sddm` |
| Build + apply Home Manager | `hm-rebuild` |
| Find who owns a command | `pkg-owner COMMAND` |
| Decide Home Manager vs Pacman | `pkg-install PACKAGE` |

## Search Through the Bible

Examples:

```fish
config-index "backup everything"
config-index "restic"
config-index "restore system"
config-index "package owner"
config-index "grub"
```
