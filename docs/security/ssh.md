---
title: SSH
category: Security
managed_by: Fish + systemd user + KDE Wallet
source: ~/dotfiles/configs/fish/conf.d/ssh-agent.fish
runtime: $XDG_RUNTIME_DIR/ssh-agent.socket
tags: ssh ssh-agent ksshaskpass kwallet git ed25519
status: active
criticality: critical
last_verified: 2026-08-26
---

# SSH

## Overview

SSH authentication uses a systemd-user SSH agent socket plus Fish startup logic and KDE's `ksshaskpass` prompt.

Private keys are **not** stored in the dotfiles repository.

## Agent Socket

Fish exports:

```fish
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
```

The saved user-service inventory shows:

```text
ssh-agent.socket enabled
```

## Automatic Key Loading

In interactive Fish sessions:

1. `ssh-add -l` checks whether a key is already loaded.
2. If no key is available, Fish sets:

```text
SSH_ASKPASS=/usr/bin/ksshaskpass
SSH_ASKPASS_REQUIRE=force
```

3. It loads:

```text
~/.ssh/id_ed25519
```

using:

```fish
ssh-add ~/.ssh/id_ed25519 </dev/null
```

The forced askpass environment allows the graphical KDE prompt to handle the key passphrase.

## Check Agent

```fish
echo $SSH_AUTH_SOCK
```

Expected path resembles:

```text
/run/user/<uid>/ssh-agent.socket
```

Check loaded keys:

```fish
ssh-add -l
```

## Add the Key Manually

```fish
ssh-add ~/.ssh/id_ed25519
```

## Git SSH

Git itself is managed through Home Manager, while SSH supplies authentication to remotes that use an SSH URL.

Check a repository remote:

```fish
git remote -v
```

SSH-form GitHub remotes normally resemble:

```text
git@github.com:OWNER/REPOSITORY.git
```

## Backup

SSH is backed up only through the encrypted secret workflow:

```fish
backup-secrets /run/media/$USER/Linux-Backup/secrets
```

The resulting file resembles:

```text
ssh-YYYY-MM-DD_HH-MM-SS.tar.gz.gpg
```

## Caution

🛑 Do not commit:

```text
~/.ssh/id_ed25519
```

or any other private SSH key.

Public keys such as `id_ed25519.pub` are not secret, but the repository intentionally keeps SSH material separate.
