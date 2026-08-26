---
title: NextDNS
category: Network
managed_by: External service
source: Prior network testing
runtime: External DNS service
tags: nextdns dns privacy filtering
status: available
criticality: normal
last_verified: 2026-08-26
---

# NextDNS

## Role

NextDNS is an available upstream/filtering DNS provider and an existing subscription has been considered for the network.

## Historical Test Notes

Previously measured resolver response times were generally in the tens of milliseconds, with occasional higher first-query samples.

The practical issue was not only raw latency: the network sometimes felt slow/laggy while using it, which motivated evaluating alternatives.

## Use Cases

Useful when wanting:

- hosted DNS filtering
- blocklists
- analytics/configuration without self-hosting
- policy applied to roaming devices

## Status

Not documented here as the authoritative active resolver.

If NextDNS becomes the final primary upstream, record the exact router/local-DNS configuration here without storing private account credentials.
