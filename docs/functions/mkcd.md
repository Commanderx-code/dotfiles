---
title: mkcd
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/mkcd.fish
runtime: ~/.config/fish/functions/mkcd.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `mkcd`

## Purpose
Custom Fish function `mkcd`.

## Usage
Inspect the live definition with:
```fish
type mkcd
functions mkcd
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/mkcd.fish
cd ~/dotfiles
git add configs/fish/functions/mkcd.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/mkcd.fish
```

## Current Implementation
```fish
function mkcd
    if test (count $argv) -lt 1
        echo "Usage: mkcd <dir>"
        return 1
    end
    mkdir -p -- $argv[1]
    cd -- $argv[1]
end
```
