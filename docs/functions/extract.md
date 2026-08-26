---
title: extract
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/extract.fish
runtime: ~/.config/fish/functions/extract.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `extract`

## Purpose
Custom Fish function `extract`.

## Usage
Inspect the live definition with:
```fish
type extract
functions extract
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/extract.fish
cd ~/dotfiles
git add configs/fish/functions/extract.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/extract.fish
```

## Current Implementation
```fish
function extract
    if not test -f $argv[1]
        echo "❌ File not found: $argv[1]"
        return 1
    end

    switch $argv[1]
        case "*.tar.bz2"
            tar xvjf $argv[1]
        case "*.tar.gz"
            tar xvzf $argv[1]
        case "*.bz2"
            bunzip2 $argv[1]
        case "*.rar"
            unrar x $argv[1]
        case "*.gz"
            gunzip $argv[1]
        case "*.tar"
            tar xvf $argv[1]
        case "*.tbz2"
            tar xvjf $argv[1]
        case "*.tgz"
            tar xvzf $argv[1]
        case "*.zip"
            unzip $argv[1]
        case "*.7z"
            7z x $argv[1]
        case "*"
            echo "Unknown archive: $argv[1]"
    end
end
```
