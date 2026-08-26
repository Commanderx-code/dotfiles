---
title: Network Security Architecture
category: Network
managed_by: Mixed
source: Current workstation config + network planning
runtime: Workstation + router/firewall
tags: security firewall opnsense ufw apparmor tailscale
status: evolving
criticality: critical
last_verified: 2026-08-26
---

# Network Security Architecture

## Layered Model

The intended security model uses multiple independent layers:

```text
Internet
  ↓
Router / future OPNsense gateway
  ↓
Network segmentation / firewall policy
  ↓
Workstation UFW
  ↓
AppArmor
  ↓
Application-level authentication/permissions
```

Tailscale adds a separate encrypted remote-access overlay.

## Workstation

Currently documented:

- UFW enabled
- SSH port rate-limited
- ports 80/443 allowed
- AppArmor enabled
- NetworkManager active
- tailscaled enabled

## Future Gateway

OPNsense is planned to centralize network-edge security and segmentation.

## IoT / Homelab Direction

Future VLANs/subnets should separate categories such as:

- trusted clients
- IoT/smart-home
- servers/homelab
- guest devices
- cameras/NVR infrastructure

Exact segmentation is not yet encoded in Batch 4 and should be documented once deployed.
