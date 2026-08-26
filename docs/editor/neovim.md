---
title: Neovim / LazyVim
category: Editor
managed_by: Home Manager
source: ~/dotfiles/configs/nvim
runtime: ~/.config/nvim
tags: neovim lazyvim lua editor
status: active
criticality: important
last_verified: 2026-08-26
---
# Neovim / LazyVim

## Architecture
`init.lua` loads `config.lazy`, which bootstraps lazy.nvim, imports LazyVim core, enabled extras, and finally custom plugins.

## Enabled LazyVim extras
- Neo-tree
- fzf
- TypeScript
- Go
- Rust
- Python
- JSON
- Prettier
- Alpha dashboard
- mini-animate

## Custom areas
- Alpha/Revan dashboard
- autosave and format-on-save behavior
- custom keymaps
- direct LSP setup
- LuaSnip snippets
- Neo-tree behavior and transparency handling
- Ruff formatting/linting
- multiple installed colorschemes

## Diagnostics
```vim
:checkhealth
:Lazy
:LspInfo
:Mason
```
