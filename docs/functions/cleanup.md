---
title: cleanup
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/cleanup.fish
runtime: ~/.config/fish/functions/cleanup.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `cleanup`

## Purpose
Clean caches and remove unused packages (CachyOS/Arch)

## Usage
Inspect the live definition with:
```fish
type cleanup
functions cleanup
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/cleanup.fish
cd ~/dotfiles
git add configs/fish/functions/cleanup.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/cleanup.fish
```

## Current Implementation
```fish
function cleanup --description "Clean caches and remove unused packages (CachyOS/Arch)"
    echo "🧹 Cleaning system..."

    # --- Pacman orphans ---
    if command -q pacman
        set -l orphans (pacman -Qtdq 2>/dev/null)
        if test -n "$orphans"
            echo "🗑 Removing orphan packages..."
            sudo pacman -Rns $orphans
        end
    end

    # --- Pacman cache (requires pacman-contrib for paccache) ---
    if command -q paccache
        echo "🧺 Cleaning pacman cache..."
        # keep last 3 versions (safe default)
        sudo paccache -r
        sudo paccache -rk3
    else
        echo "ℹ️ Install pacman-contrib for cache cleanup: sudo pacman -S pacman-contrib"
    end

    # --- Flatpak unused ---
    if command -q flatpak
        echo "📦 Removing unused Flatpaks..."
        flatpak uninstall --unused -y
    end

    # --- Journal logs (keep last 7 days) ---
    if command -q journalctl
        sudo journalctl --vacuum-time=7d >/dev/null 2>&1
    end

    echo "✅ Cleanup complete"
end
```
