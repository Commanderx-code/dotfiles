---
title: Neovim Troubleshooting
category: Troubleshooting
managed_by: Home Manager
source: ~/dotfiles/configs/nvim
runtime: ~/.config/nvim
tags: neovim troubleshooting lazyvim
status: active
criticality: important
last_verified: 2026-08-26
---
# Neovim Troubleshooting

## Python provider
The config points Neovim at `~/.venvs/nvim/bin/python`. Perl and Ruby providers are intentionally disabled.

## Current review notes
- `options.lua` assigns `vim.g.autoformat` multiple times; the final effective value is `true`.
- Alpha status/tab/cmdline hiding exists in both `config/alpha_hidebars.lua` and `plugins/alpha-statusline-fix.lua`.
- The Poimandres plugin block invokes the `eldritch` colorscheme; LazyVim is also configured for `eldritch`.
- Cody keymaps contain `remap = ture` in the current source.
- ElixirLS is configured with `{ "elixir-ls", "--studio" }`; if it fails, verify the installed command's supported arguments.
