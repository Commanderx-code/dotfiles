---
title: Ghostty
category: Terminal
managed_by: Dotfiles / manual
source: ~/dotfiles/configs/ghostty
runtime: Ghostty configuration
tags: ghostty terminal fish spotatui
status: active
criticality: normal
last_verified: 2026-08-26
---

# Ghostty

## Current Batch 3 Source

The uploaded configuration contains:

```text
configs/ghostty/spotatui.conf
```

with:

```text
config-default-files = true
initial-command = fish
```

## Purpose

This profile is used with the custom:

```fish
spotatui-ghostty
```

Fish function so Spotatui can be launched in a dedicated Ghostty window while still starting Fish normally.

## Related Function

```fish
spotatui-ghostty
```

Search:

```fish
config-index spotatui
```

## Note

This batch does not contain a general `configs/ghostty/config` file, so the Bible only documents the Ghostty configuration actually present in the uploaded source.
