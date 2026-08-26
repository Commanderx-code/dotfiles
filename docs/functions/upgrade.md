---
title: upgrade
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/upgrade.fish
runtime: ~/.config/fish/functions/upgrade.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `upgrade`

## Purpose
Upgrade packages (pacman + paru + flatpak)

## Usage
Inspect the live definition with:
```fish
type upgrade
functions upgrade
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/upgrade.fish
cd ~/dotfiles
git add configs/fish/functions/upgrade.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/upgrade.fish
```

## Current Implementation
```fish
function upgrade --description "Upgrade packages (pacman + paru + flatpak)"
    sudo pacman -Syu
    paru -Syu

    if command -q flatpak
        flatpak update -y
    end
end
```
