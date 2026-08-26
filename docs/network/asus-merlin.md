---
title: ASUS Router / Asuswrt-Merlin
category: Network
managed_by: External router
source: Prior network design
runtime: ASUS router
tags: asus merlin router wifi firmware
status: external
criticality: important
last_verified: 2026-08-26
---

# ASUS Router / Asuswrt-Merlin

## Context

The current network has used an ASUS router, and Asuswrt-Merlin has been evaluated as an alternative to stock ASUS firmware.

## Why Merlin Was Considered

The goal was to gain more advanced router control while retaining the familiar ASUS platform.

## Architecture Direction

Longer-term planning has shifted toward a dedicated OPNsense firewall/router.

In that design, the ASUS hardware can remain useful primarily for Wi-Fi/access-point duties rather than being the main security gateway.

## Status

This is an external-device reference page.

No live router configuration export was included in Batch 4.

When the final router architecture is chosen, add:

- model
- firmware version
- LAN subnet
- Wi-Fi bands/SSIDs
- DHCP role
- DNS role
- AP/router mode
- backup/export procedure
