---
title: lazyg
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/lazyg.fish
runtime: ~/.config/fish/functions/lazyg.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `lazyg`

## Purpose
Custom Fish function `lazyg`.

## Usage
Inspect the live definition with:
```fish
type lazyg
functions lazyg
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/lazyg.fish
cd ~/dotfiles
git add configs/fish/functions/lazyg.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/lazyg.fish
```

## Current Implementation
```fish
function lazyg
    git add .
    if test (count $argv) -eq 0
        echo "Usage: lazyg <message>"
        return 1
    end
    git commit -m (string join ' ' -- $argv)
    git push
end
```
