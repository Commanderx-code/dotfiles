---
title: SSH Agent Startup
category: Security
managed_by: Fish + systemd user
source: ~/dotfiles/configs/fish/conf.d/ssh-agent.fish
runtime: $XDG_RUNTIME_DIR/ssh-agent.socket
tags: ssh agent fish systemd
status: active
criticality: important
last_verified: 2026-08-26
---

# SSH Agent Startup

## Fish Files

```text
configs/fish/conf.d/ssh-agent.fish
configs/fish/conf.d/ssh-add.fish
```

## `ssh-agent.fish`

Defines the agent socket for every Fish process:

```fish
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
```

## `ssh-add.fish`

Runs only in an interactive shell.

It checks:

```fish
ssh-add -l
```

If no identity is available, it loads:

```text
~/.ssh/id_ed25519
```

with a forced `ksshaskpass` graphical prompt.

## Troubleshooting

Check the socket unit:

```fish
systemctl --user status ssh-agent.socket
```

Check the environment:

```fish
echo $SSH_AUTH_SOCK
```

Check identities:

```fish
ssh-add -l
```

Start a fresh shell after Fish configuration changes:

```fish
exec fish
```
