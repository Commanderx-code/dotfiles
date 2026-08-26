---
title: Tailscale
category: Network
managed_by: System / Homelab
source: service inventory + prior homelab design
runtime: tailscaled
tags: tailscale vpn overlay remote-access zimaboard subnet-router
status: active-external
criticality: important
last_verified: 2026-08-26
---

# Tailscale

## Workstation State

The saved system-service inventory shows:

```text
tailscaled.service enabled
```

## Homelab Context

Tailscale has also been used/planned on the ZimaBoard side, including a containerized setup with subnet routing for:

```text
192.168.50.0/24
```

That homelab configuration is external to the workstation Batch 4 source.

## Workstation Commands

Status:

```fish
tailscale status
```

Address:

```fish
tailscale ip
```

Service:

```fish
systemctl status tailscaled
```

## Security Note

Tailscale provides encrypted overlay connectivity but does not replace host firewall policy.

Keep UFW/AppArmor and service-level access controls in place.
