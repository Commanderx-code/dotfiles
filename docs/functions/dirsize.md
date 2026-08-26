---
title: dirsize
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/dirsize.fish
runtime: ~/.config/fish/functions/dirsize.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `dirsize`

## Purpose
Custom Fish function `dirsize`.

## Usage
Inspect the live definition with:
```fish
type dirsize
functions dirsize
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/dirsize.fish
cd ~/dotfiles
git add configs/fish/functions/dirsize.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/dirsize.fish
```

## Current Implementation
```fish
function dirsize
    du -sh .
end
```
