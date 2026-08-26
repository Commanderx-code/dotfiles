---
title: Config Bible Workflow
category: Commands
managed_by: Documentation
source: ~/dotfiles/docs
runtime:
tags: bible workflow documentation config-index
status: active
criticality: important
last_verified: 2026-08-26
---

# Config Bible Workflow

## Find Something

```fish
config-index
```

Or pre-filter:

```fish
config-index grub
config-index neovim
config-index backup
```

## Make a Change

### Home Manager-managed

```fish
nvim ~/dotfiles/path/to/source
git add path/to/new/file   # required for brand-new flake files
hms
```

### System-managed

1. Read the corresponding Bible page.
2. Back up system state if appropriate.
3. Edit the live system source carefully.
4. Apply/reload the subsystem.
5. Run `backup-system-state` after the final working configuration.

### Homelab Docker

```bash
cd /DATA/compose/STACK
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100
```

## Record the Change

Update:

```text
last_verified
Known Issues / History
Why This Is Configured This Way
Troubleshooting
```

when a meaningful behavior or recovery procedure changes.

## Commit

```fish
cd ~/dotfiles
git status
git add docs path/to/config
git commit
```

Use a message that describes the real change rather than only saying "update docs".
