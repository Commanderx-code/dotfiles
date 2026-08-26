---
title: Topgrade
category: System
managed_by: Home Manager
source: ~/dotfiles/configs/topgrade/topgrade.toml
runtime: ~/.config/topgrade.toml
tags: topgrade update garuda home-manager flatpak rust cargo go
status: active
criticality: important
last_verified: 2026-08-26
---

# Topgrade

## Purpose

Topgrade is the main orchestration layer behind the normal full-system upgrade workflow.

Custom Fish wrapper:

```fish
full-upgrade
```

## Main Behavior

Current settings:

- assume yes
- pre-cache sudo credentials
- cleanup enabled
- retry allowed
- skipped steps hidden
- notify only on failure
- Nix handler autodetected

## Disabled Topgrade Steps

```text
nix
snap
firmware
```

## Arch / Garuda

System packages use:

```text
garuda_update
```

Arch news is displayed.

## Home Manager

Arguments point to:

```text
/home/commander/dotfiles/home-manager#commander
```

## Git

Tracked repository:

```text
~/dotfiles
```

Git updates use:

```text
--rebase --autostash
```

Concurrency:

```text
5
```

## Other Ecosystems

Topgrade is configured to handle/check:

- user Flatpaks
- pip-review
- Cargo packages, including Git installs
- stable Rust toolchain
- Go tools through `gup`
- VS Code default profile

## Normal Usage

```fish
full-upgrade
```

For development/VCS AUR packages first:

```fish
full-upgrade-devel
```

## Direct Usage

```fish
topgrade
```

## Apply

```fish
hms
```
