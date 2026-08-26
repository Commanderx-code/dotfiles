---
title: Fish Troubleshooting
category: Troubleshooting
managed_by: Home Manager
source: ~/dotfiles/configs/fish
runtime: ~/.config/fish
tags: fish troubleshooting home-manager
status: active
criticality: important
last_verified: 2026-08-26
---
# Fish Troubleshooting

## New function is missing after `hms`
Check whether the file is untracked:
```fish
cd ~/dotfiles
git status --short
```
Stage new files, then rebuild:
```fish
git add configs/fish/functions/FUNCTION.fish
hms
exec fish
```

## `find -maxdepth` fails
`find` is aliased to `fd`. Use:
```fish
command find PATH -maxdepth 3 -type f
```

## Review notes from current config
- `__fzf_starstar_tab` is defined both in its own file and inside `fish_user_key_bindings.fish`; the two implementations are similar but not identical.
- Home Manager defines an `update` alias while `functions/update.fish` defines an `update` function. Use `type -a update` if behavior is surprising.
