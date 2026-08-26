---
title: config-index
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/config-index.fish
runtime: ~/.config/fish/functions/config-index.fish
tags: fish fzf documentation database config bible navigation
status: active
criticality: important
last_verified: 2026-08-26
---

# `config-index`

## Purpose

`config-index` is the main interactive interface for the Commander Config Bible.

It searches all Markdown documentation beneath:

```text
~/dotfiles/docs
```

and presents the results through `fzf`.

## Basic Usage

```fish
config-index
```

Start with search terms:

```fish
config-index fish
config-index neovim
config-index grub
config-index docker
```

## Quick Filters

Critical pages:

```fish
config-index --critical
```

Planned items:

```fish
config-index --planned
```

Recovery-oriented search:

```fish
config-index --recovery
```

Help:

```fish
config-index --help
```

## Interface

Each entry shows:

```text
icon/status/criticality
title
category
status
criticality
relative documentation path
```

The metadata itself remains searchable even when some fields are visually compact.

## Controls

| Key | Action |
|---|---|
| `Enter` | Open documentation in Neovim |
| `Ctrl-O` | Open documented source/config |
| `Ctrl-D` | Change to source or documentation directory |
| `Ctrl-Y` | Copy documentation path |
| `Ctrl-X` | Copy documented source path |
| `Ctrl-R` | Open recovery/backup/troubleshooting chooser |
| `Ctrl-/` | Toggle preview |
| `Esc` | Exit |

## Category Icons

Examples:

```text
📚 Index
⚙  System
🐟 Shell
🛠 Function
✎  Editor
🖥 Desktop
🚀 Boot
💾 Backup
🚑 Recovery
🔐 Security
🌐 Network
🐳 Homelab
🧰 Troubleshooting
```

## Status Indicators

```text
●   active
↗   external / active-external
⚠   duplicate active definition
◌   planned
◇   available
◐   evolving
🔒  sensitive
```

## Criticality

```text
🛑 critical
!   important
```

## External Source Handling

Some Bible entries describe configurations on another machine, such as:

```text
/DATA/compose
/var/lib/casaos/apps
```

When `Ctrl-O` is used for one of those entries from the workstation, `config-index`
does not treat the missing local path as an error in the documentation. It explains
that the source belongs to an external host.

Use `Ctrl-X` to copy the documented path for use over SSH.

## Recovery Shortcut

While viewing any entry, press:

```text
Ctrl-R
```

to open a second fuzzy selector containing only:

```text
docs/recovery/
docs/backup/
docs/troubleshooting/
```

The current page title is used as the initial recovery search.

Examples:

```text
GRUB -> recovery/troubleshooting selector
SSH -> recovery/troubleshooting selector
ZimaBoard -> container recovery/troubleshooting selector
```

## Dependencies

Required:

```text
fish
fzf
awk
find
nvim
```

Recommended:

```text
bat
wl-clipboard
```

`bat` provides syntax-highlighted previews.

`wl-copy` provides clipboard support for `Ctrl-Y` and `Ctrl-X`.

## Source of Truth

```text
~/dotfiles/configs/fish/functions/config-index.fish
```

Runtime Home Manager link:

```text
~/.config/fish/functions/config-index.fish
```

## Apply Changes

For an existing tracked function:

```fish
hms
```

For a new/untracked file:

```fish
cd ~/dotfiles
git add configs/fish/functions/config-index.fish
hms
```

## Validate

Check Fish syntax:

```fish
fish -n ~/dotfiles/configs/fish/functions/config-index.fish
```

Start a fresh shell:

```fish
exec fish
```

Then:

```fish
type config-index
config-index --help
config-index
```
