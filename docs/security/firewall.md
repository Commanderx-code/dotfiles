---
title: UFW Firewall
category: Security
managed_by: System / UFW
source: ~/dotfiles/system-backup/firewall/ufw
runtime: /etc/ufw
tags: ufw firewall iptables ipv4 ipv6 ssh web security
status: active
criticality: critical
last_verified: 2026-08-26
---

# UFW Firewall

## Overview

UFW is enabled on the workstation and its complete `/etc/ufw` state is included in the system snapshot.

Saved source:

```text
~/dotfiles/system-backup/firewall/ufw
```

Runtime:

```text
/etc/ufw
```

## Service State

The saved system-service inventory shows:

```text
ufw.service enabled
```

UFW is also configured to start at boot:

```ini
ENABLED=yes
LOGLEVEL=low
```

## Current User Rules

The saved IPv4 and IPv6 rules allow/limit:

| Port | Protocol | Action | Purpose |
|---|---|---|---|
| 22 | TCP | `limit` | SSH with connection-rate limiting |
| 80 | TCP | `allow` | HTTP |
| 443 | TCP | `allow` | HTTPS |

The same user rules exist for IPv4 and IPv6.

### SSH Rate Limiting

New SSH connections are rate-limited. The generated rules track connection attempts and invoke UFW's limit chain when the threshold is exceeded.

Normal UFW command:

```fish
sudo ufw limit 22/tcp
```

## Logging

Saved UFW log level:

```text
low
```

Generated rules use prefixes including:

```text
[UFW BLOCK]
[UFW ALLOW]
[UFW LIMIT BLOCK]
```

## Useful Commands

Status:

```fish
sudo ufw status verbose
```

Numbered rules:

```fish
sudo ufw status numbered
```

Enable:

```fish
sudo ufw enable
```

Reload:

```fish
sudo ufw reload
```

Logs:

```fish
journalctl -k | rg 'UFW'
```

## Important Caution

🛑 When configuring UFW remotely over SSH, allow or limit SSH **before** enabling/reloading the firewall.

Example:

```fish
sudo ufw limit 22/tcp
sudo ufw enable
```

## Backup

```fish
backup-system-state
```

## Restore

```fish
restore-system
```

The restore workflow is interactive. Review rules before applying them on a machine whose network role has changed.
