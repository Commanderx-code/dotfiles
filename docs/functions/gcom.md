---
title: gcom
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/gcom.fish
runtime: ~/.config/fish/functions/gcom.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `gcom`

## Purpose
Custom Fish function `gcom`.

## Usage
Inspect the live definition with:
```fish
type gcom
functions gcom
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/gcom.fish
cd ~/dotfiles
git add configs/fish/functions/gcom.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/gcom.fish
```

## Current Implementation
```fish
function gcom
    git add .
    if test (count $argv) -eq 0
        echo "Usage: gcom <message>"
        return 1
    end
    git commit -m (string join ' ' -- $argv)
end
```
