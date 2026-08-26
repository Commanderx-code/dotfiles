---
title: hm-rebuild
category: Function
managed_by: Home Manager
source: ~/dotfiles/home-manager/scripts/hm-rebuild.fish
runtime: ~/.local/bin/hm-rebuild
tags: hm rebuild backup recovery home-manager
status: active
criticality: important
last_verified: 2026-08-26
---


# `hm-rebuild`

## Purpose

Safely build and then switch the Home Manager configuration.

## Usage

```fish
hm-rebuild
```

## Workflow

1. Verify `~/dotfiles/home-manager` exists.
2. Change to `~/dotfiles`.
3. Show `git status --short`.
4. Build:

```fish
home-manager build --flake ./home-manager#commander
```

5. Only if the build succeeds, switch:

```fish
home-manager switch --flake ./home-manager#commander
```

If build fails, no switch is performed.

## Important Git-Flake Rule

Brand-new untracked files may not be visible to the flake.

For a newly-created config file:

```fish
git add path/to/new/file
hm-rebuild
```
