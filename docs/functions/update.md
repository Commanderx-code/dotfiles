---
title: update
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/update.fish
runtime: ~/.config/fish/functions/update.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `update`

## Purpose
Show available updates (Arch)

## Usage
Inspect the live definition with:
```fish
type update
functions update
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/update.fish
cd ~/dotfiles
git add configs/fish/functions/update.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/update.fish
```

## Current Implementation
```fish
function update --description "Show available updates (Arch)"
    if command -q checkupdates
        checkupdates
        return
    end

    echo "Tip: install pacman-contrib for checkupdates: sudo pacman -S pacman-contrib"
    sudo pacman -Sy
    pacman -Qu
end
```
