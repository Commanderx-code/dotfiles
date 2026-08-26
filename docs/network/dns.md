---
title: DNS Strategy
category: Network
managed_by: External infrastructure / planning
source: Prior system design
runtime: Router / future local DNS server
tags: dns nextdns technitium cloudflare quad9 raspberry-pi
status: planned
criticality: important
last_verified: 2026-08-26
---

# DNS Strategy

## Current Design Direction

DNS has been evaluated as part of the broader homelab/network plan rather than stored as a workstation dotfile.

Resolvers previously tested include:

- Quad9
- Cloudflare
- NextDNS

The longer-term plan has considered moving primary local DNS duties to Technitium DNS, potentially on a Raspberry Pi 5.

## NextDNS

NextDNS is available as a managed/filtering DNS option.

Historical testing showed acceptable latency most of the time but there were periods where it felt slower/laggier than desired.

## Technitium DNS

Planned as a possible self-hosted local DNS resolver/filtering platform.

Potential benefits in the intended architecture:

- local control
- caching
- custom zones/records
- centralized DNS policy
- less dependence on per-device settings

## Important Status

This page is a design/reference page.

No live Technitium, NextDNS, or router DNS configuration was included in Batch 4, so do not treat the values here as an authoritative active DNS configuration.

## Future Documentation

When Technitium is deployed, record:

- host/IP
- upstream resolvers
- blocklists
- local zones
- DHCP relationship
- fallback DNS
- backup/export procedure
