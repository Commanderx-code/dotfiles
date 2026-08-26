---
title: fcd
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/fcd.fish
runtime: ~/.config/fish/functions/fcd.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `fcd`

## Purpose
Custom Fish function `fcd`.

## Usage
Inspect the live definition with:
```fish
type fcd
functions fcd
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/fcd.fish
cd ~/dotfiles
git add configs/fish/functions/fcd.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/fcd.fish
```

## Current Implementation
```fish
function fcd
    set dir (eza -D --color=always | fzf)
    if test -n "$dir"
        cd $dir
    end
end
```
