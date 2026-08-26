---
title: psg
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/psg.fish
runtime: ~/.config/fish/functions/psg.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `psg`

## Purpose
Custom Fish function `psg`.

## Usage
Inspect the live definition with:
```fish
type psg
functions psg
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/psg.fish
cd ~/dotfiles
git add configs/fish/functions/psg.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/psg.fish
```

## Current Implementation
```fish
function psg
    if test (count $argv) -lt 1
        echo "Usage: psg <pattern>"
        return 1
    end

    if command -q pgrep
        pgrep -ai -- $argv[1]
    else
        ps aux | rg -i -- $argv[1]
    end
end
```
