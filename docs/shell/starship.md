---
title: Starship Prompt
category: Shell
managed_by: Home Manager
source: ~/dotfiles/configs/starship/starship.toml
runtime: ~/.config/starship.toml
tags: starship fish prompt git developer
status: active
criticality: normal
last_verified: 2026-08-26
---

# Starship Prompt

## Home Manager

Starship is enabled with Fish integration.

Source:

```text
~/dotfiles/configs/starship/starship.toml
```

Runtime:

```text
~/.config/starship.toml
```

## Prompt Layout

The prompt is a two-line Powerline-style layout.

It can display:

- Python environment
- username
- directory
- Git branch
- Git status
- C
- Go
- Java
- Rust
- Docker context
- current time
- command exit status
- package information

## Prompt Symbols

Success:

```text
λ
```

Failure:

```text
×
```

Status indicator:

```text
●
```

## Directory

- truncation length: 3
- truncate to Git repository: enabled
- read-only indicator: lock icon
- special icons for Documents, Downloads, Music, Pictures

## Git Status

Custom symbols are configured for:

- conflicted
- ahead
- behind
- diverged
- untracked
- stashed
- modified
- staged
- renamed
- deleted

## Time

12-hour time is shown with:

```text
🕙 %I:%M %p
```

## Apply

```fish
hms
```

A new Fish shell will use the rebuilt prompt.
