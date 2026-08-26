---
title: Security and Network Troubleshooting
category: Troubleshooting
managed_by: Documentation
source: ~/dotfiles/system-backup/firewall + Fish SSH config
runtime:
tags: ufw ssh kwallet networkmanager tailscale apparmor troubleshooting
status: active
criticality: important
last_verified: 2026-08-26
---

# Security and Network Troubleshooting

## SSH Key Keeps Asking for a Passphrase

Check:

```fish
systemctl --user status ssh-agent.socket
echo $SSH_AUTH_SOCK
ssh-add -l
```

If no identity is loaded:

```fish
ssh-add ~/.ssh/id_ed25519
```

The interactive Fish startup uses `ksshaskpass`.

## `SSH_AUTH_SOCK` Is Wrong or Missing

Start a fresh Fish shell:

```fish
exec fish
```

Expected configuration:

```fish
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
```

## UFW Blocks Something Unexpected

```fish
sudo ufw status numbered
sudo ufw status verbose
journalctl -k | rg 'UFW'
```

Do not disable the firewall as the first troubleshooting step. Identify the required port/service and add a narrowly-scoped rule.

## AppArmor Blocks an Application

```fish
sudo aa-status
journalctl -k | rg -i apparmor
```

Review the relevant profile rather than globally disabling AppArmor.

## NetworkManager Issues

```fish
nmcli device
nmcli connection show --active
systemctl status NetworkManager
```

## Tailscale Issues

```fish
systemctl status tailscaled
tailscale status
```

## Restic Cannot Read KWallet Credential

```fish
kwallet-query -f Restic -r Crucial-X6 kdewallet
```

If KDE Wallet is unavailable during disaster recovery, use the standalone GPG-encrypted Restic recovery credential documented in the recovery section.
