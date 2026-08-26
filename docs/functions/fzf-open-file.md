---
title: fzf_open_file
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/fzf_open_file.fish
runtime: ~/.config/fish/functions/fzf_open_file.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `fzf_open_file`

## Purpose
FZF pick a file and open in nvim

## Usage
Inspect the live definition with:
```fish
type fzf_open_file
functions fzf_open_file
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/fzf_open_file.fish
cd ~/dotfiles
git add configs/fish/functions/fzf_open_file.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/fzf_open_file.fish
```

## Current Implementation
```fish
function fzf_open_file --description "FZF pick a file and open in nvim"
    if not command -q fzf
        echo "fzf not installed"
        return 1
    end

    if not command -q fd
        echo "fd not installed"
        return 1
    end

    set -l preview "$HOME/.local/bin/fzf-preview"

    if not test -x "$preview"
        echo "fzf preview script missing:"
        echo "$preview"
        return 1
    end

    set -l file (
        fd --type f --hidden --follow \
            --exclude .git \
            --exclude node_modules \
            --exclude .cache \
            --exclude .cargo \
            --exclude go/pkg/mod \
            --exclude .local/share \
            2>/dev/null |
        fzf \
            --layout=reverse \
            --border \
            --ansi \
            --preview-window='right,60%,nowrap' \
            --preview="$preview {}" \
            --bind='ctrl-/:toggle-preview'
    )

    test -z "$file"; and return

    commandline -r -- (string join ' ' -- nvim (string escape -- $file))
    commandline -f execute
end
```
