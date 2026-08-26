---
title: OPNsense
category: Network
managed_by: Planned dedicated firewall
source: Prior network/homelab planning
runtime: Future firewall appliance
tags: opnsense firewall router ids ips wireguard vlan
status: planned
criticality: critical
last_verified: 2026-08-26
---

# OPNsense

## Decision

OPNsense has been selected as the preferred direction for the future dedicated firewall/router.

## Hardware Goals

The appliance search has focused on:

- Intel x86 hardware
- multi-NIC fanless firewall appliances
- N100/N305-class options and stronger mobile Intel CPUs
- enough CPU headroom for IDS/IPS and VPN workloads
- approximately 16 GB RAM
- practical SSD capacity rather than minimal embedded storage

## Intended Responsibilities

Possible OPNsense responsibilities:

- WAN routing
- stateful firewall
- VLAN segmentation
- DHCP
- DNS integration
- WireGuard/VPN
- IDS/IPS
- policy separation between trusted, IoT, guest, and infrastructure networks

## ASUS Relationship

Once OPNsense becomes the gateway, the existing ASUS device can be repurposed toward wireless access-point duties.

## Status

Planned. No live OPNsense configuration backup exists in Batch 4.

## Future Bible Fields

When deployed, record:

```text
hardware model
NIC mapping
WAN interface
LAN/VLAN interfaces
subnets
DHCP ranges
DNS servers
firewall rules
aliases
NAT rules
WireGuard configuration
IDS/IPS policies
config.xml backup procedure
upgrade procedure
rollback procedure
```

🛑 Do not commit an OPNsense configuration export to a public repository without first reviewing it for secrets.
