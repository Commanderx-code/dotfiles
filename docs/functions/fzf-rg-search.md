---
title: fzf_rg_search
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/fzf_rg_search.fish
runtime: ~/.config/fish/functions/fzf_rg_search.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `fzf_rg_search`

## Purpose
Search text with ripgrep + fzf and open result in nvim

## Usage
Inspect the live definition with:
```fish
type fzf_rg_search
functions fzf_rg_search
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/fzf_rg_search.fish
cd ~/dotfiles
git add configs/fish/functions/fzf_rg_search.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/fzf_rg_search.fish
```

## Current Implementation
```fish
function fzf_rg_search --description "Search text with ripgrep + fzf and open result in nvim"
    if not command -q rg
        echo "ripgrep not installed: sudo pacman -S ripgrep"
        return 1
    end

    if not command -q fzf
        echo "fzf not installed: sudo pacman -S fzf"
        return 1
    end

    set -l q
    read -l -P "Search text: " q

    test -z "$q"; and return 0

    set -l results (
        rg \
            --line-number \
            --column \
            --no-heading \
            --smart-case \
            --hidden \
            --color=always \
            --glob '!.git/*' \
            --glob '!node_modules/*' \
            --glob '!.cache/*' \
            --glob '!.local/share/Trash/*' \
            --glob '!.local/share/Steam/*' \
            -- "$q" "$PWD" "$HOME/.local/bin" 2>/dev/null
    )

    if test (count $results) -eq 0
        echo "No matches found for: $q"
        return 0
    end

    set -l pick (
        printf "%s\n" $results |
        fzf \
            --ansi \
            --layout=reverse \
            --border \
            --delimiter ':' \
            --preview='bat --style=numbers --color=always --highlight-line {2} --line-range :300 {1} 2>/dev/null' \
            --preview-window='right,60%,nowrap' \
            --bind='ctrl-/:toggle-preview'
    )

    test -z "$pick"; and return 0

    set -l file (string split -m1 ':' -- "$pick")[1]
    set -l line (string split -m2 ':' -- "$pick")[2]

    if command -q nvim
        commandline -r -- (string join ' ' -- nvim "+$line" (string escape -- "$file"))
        commandline -f execute
    else
        echo "$file:$line"
    end
end
```
