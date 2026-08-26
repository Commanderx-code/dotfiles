---
title: Fastfetch
category: Desktop
managed_by: Home Manager
source: ~/dotfiles/configs/fastfetch
runtime: ~/.config/fastfetch
tags: fastfetch system-info kitty garuda
status: active
criticality: normal
last_verified: 2026-08-26
---

# Fastfetch

## Home Manager

`programs.fastfetch.enable = true`.

The complete source tree is recursively linked:

```text
~/dotfiles/configs/fastfetch
  -> ~/.config/fastfetch
```

## Logo

The active config uses Kitty image protocol:

```text
type: kitty
source: /usr/share/icons/garuda/ninja.png
width: 24
```

## Information Displayed

The current module layout includes:

- distro
- kernel
- packages
- installation age in days
- shell
- desktop/window manager
- WM theme
- icon theme
- cursor
- terminal font
- terminal
- host
- CPU
- GPU
- display
- memory
- swap
- uptime
- local IPv4 address
- Wi-Fi SSID
- audio device
- media player
- current media

## Custom Network Commands

Local IPv4 is determined through:

```sh
ip -4 route get 1.1.1.1
```

Wi-Fi SSID uses `iwgetid` first and falls back to `nmcli`.

## Run

```fish
fastfetch
```

## Apply

```fish
hms
```
