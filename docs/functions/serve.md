---
title: serve
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/serve.fish
runtime: ~/.config/fish/functions/serve.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `serve`

## Purpose
Custom Fish function `serve`.

## Usage
Inspect the live definition with:
```fish
type serve
functions serve
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/serve.fish
cd ~/dotfiles
git add configs/fish/functions/serve.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/serve.fish
```

## Current Implementation
```fish
function serve
    set -l port 8000
    if test (count $argv) -ge 1
        set port $argv[1]
    end

    if command -q python3
        python3 -m http.server $port
    else
        python -m http.server $port
    end
end
```
