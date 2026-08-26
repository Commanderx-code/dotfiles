---
title: Home Manager - Fish and Neovim
category: System
managed_by: Home Manager
source: ~/dotfiles/home-manager/modules
runtime: ~/.config
tags: home-manager fish neovim nix
status: active
criticality: important
last_verified: 2026-08-26
---
# Home Manager - Fish and Neovim

`fish.nix` enables Fish, zoxide, and fzf and recursively links the Fish `conf.d` and `functions` trees. `nvim.nix` installs Neovim and recursively links `configs/nvim` to `~/.config/nvim`.

Rebuild with:
```fish
hms
```
