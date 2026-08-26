---
title: br
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/br.fish
runtime: ~/.config/fish/functions/br.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `br`

## Purpose
This function starts broot and executes the command it produces, if any.

## Usage
Inspect the live definition with:
```fish
type br
functions br
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/br.fish
cd ~/dotfiles
git add configs/fish/functions/br.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/br.fish
```

## Current Implementation
```fish
# This function starts broot and executes the command it produces, if any.
# Needed because commands like `cd` must run in the current shell.

function br --wraps=broot
    set -l cmd_file (mktemp)

    if broot --outcmd $cmd_file $argv
        source $cmd_file
        rm -f $cmd_file
    else
        set -l code $status
        rm -f $cmd_file
        return $code
    end
end
```
