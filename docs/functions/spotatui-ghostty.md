---
title: spotatui-ghostty
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/spotatui-ghostty.fish
runtime: ~/.config/fish/functions/spotatui-ghostty.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `spotatui-ghostty`

## Purpose
Custom Fish function `spotatui-ghostty`.

## Usage
Inspect the live definition with:
```fish
type spotatui-ghostty
functions spotatui-ghostty
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/spotatui-ghostty.fish
cd ~/dotfiles
git add configs/fish/functions/spotatui-ghostty.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/spotatui-ghostty.fish
```

## Current Implementation
```fish
function spotatui-ghostty
    touch "$XDG_RUNTIME_DIR/spotatui-autostart"
    ghostty +new-window
end
```
