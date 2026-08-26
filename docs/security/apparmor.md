---
title: AppArmor
category: Security
managed_by: System
source: system service inventory
runtime: /etc/apparmor.d
tags: apparmor lsm mac security
status: active
criticality: important
last_verified: 2026-08-26
---

# AppArmor

## Current State

The saved system-service inventory shows:

```text
apparmor.service enabled
```

The GRUB configuration documented elsewhere also includes AppArmor among the enabled Linux Security Modules.

## Purpose

AppArmor provides mandatory access control (MAC) by constraining applications with security profiles.

It complements UFW:

```text
UFW       -> controls network traffic
AppArmor  -> constrains what processes can access/do
```

Neither replaces the other.

## Useful Commands

Service:

```fish
systemctl status apparmor
```

Loaded/enforced profiles:

```fish
sudo aa-status
```

Reload a profile:

```fish
sudo apparmor_parser -r /etc/apparmor.d/PROFILE
```

## Source Status

Batch 4 contains service/inventory evidence that AppArmor is active, but does **not** contain custom `/etc/apparmor.d` profile files.

Therefore this Bible page documents the system role and verification workflow without claiming that custom AppArmor profiles are stored in the dotfiles repository.
