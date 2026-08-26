---
title: full-upgrade
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/full-upgrade.fish
runtime: ~/.config/fish/functions/full-upgrade.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `full-upgrade`

## Purpose
Run full system and development environment upgrade

## Usage
Inspect the live definition with:
```fish
type full-upgrade
functions full-upgrade
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/full-upgrade.fish
cd ~/dotfiles
git add configs/fish/functions/full-upgrade.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/full-upgrade.fish
```

## Current Implementation
```fish
function full-upgrade --description "Run full system and development environment upgrade"
    echo " Running full system upgrade..."
    echo

    if not command -q topgrade
        echo "ℹ️ topgrade not installed (install: sudo pacman -S topgrade)"
        return 1
    end

    echo "📦 Updating system packages..."

    echo " Running Topgrade..."
    topgrade
    set -l status_code $status

    echo

    if test $status_code -eq 0
        echo "✅ Full upgrade complete"
    else
        echo "❌ Full upgrade finished with errors"
    end

    return $status_code
end
```
