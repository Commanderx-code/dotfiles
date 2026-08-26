---
title: UFW Network Hardening Sysctl
category: Security
managed_by: UFW
source: ~/dotfiles/system-backup/firewall/ufw/sysctl.conf
runtime: /etc/ufw/sysctl.conf
tags: ufw sysctl network hardening spoofing redirects
status: active
criticality: important
last_verified: 2026-08-26
---

# UFW Network Hardening Sysctl

## Purpose

`/etc/ufw/sysctl.conf` applies networking sysctl values used alongside the firewall.

## Forwarding

IPv4/IPv6 packet forwarding is **not enabled** in the saved UFW sysctl file.

This workstation is therefore not configured here to act as a router.

## Reverse-Path Filtering

Enabled:

```text
net/ipv4/conf/default/rp_filter=1
net/ipv4/conf/all/rp_filter=1
```

This provides source-address verification intended to reduce spoofed traffic.

## Source Routing

Disabled for IPv4 and IPv6:

```text
accept_source_route=0
```

## ICMP Redirects

Disabled for IPv4 and IPv6:

```text
accept_redirects=0
```

This avoids accepting redirect messages that could be abused in some man-in-the-middle scenarios.

## ICMP Behavior

Broadcast echo requests are ignored:

```text
icmp_echo_ignore_broadcasts=1
```

Bogus error responses are ignored:

```text
icmp_ignore_bogus_error_responses=1
```

Normal direct ping responses remain enabled:

```text
icmp_echo_ignore_all=0
```

## Apply / Reload

UFW normally applies its sysctl file as part of its startup/reload behavior.

After changing firewall sysctl configuration:

```fish
sudo ufw reload
```

If testing individual sysctl values, use `sysctl` carefully and document permanent changes in the UFW source.
