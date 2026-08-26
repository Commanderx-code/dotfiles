---
title: NetworkManager
category: Network
managed_by: System
source: system service inventory
runtime: /etc/NetworkManager + NetworkManager connections
tags: networkmanager networking wifi ethernet nmcli
status: active
criticality: critical
last_verified: 2026-08-26
---

# NetworkManager

## Current State

The saved service inventory includes:

```text
NetworkManager.service
NetworkManager-dispatcher.service
NetworkManager-wait-online.service
```

as enabled system units.

## Role

NetworkManager is the workstation's network-management layer for Ethernet/Wi-Fi and connection profiles.

## Useful Commands

Devices:

```fish
nmcli device
```

Connections:

```fish
nmcli connection show
```

Current active connection:

```fish
nmcli connection show --active
```

Wi-Fi:

```fish
nmcli device wifi list
```

## Secret Policy

NetworkManager connection profiles may contain credentials.

They are intentionally **not** included in the public dotfiles snapshot/repository.

Do not commit:

```text
/etc/NetworkManager/system-connections/*.nmconnection
```

## Recovery

Recreate or restore sensitive connection profiles separately rather than treating them as public dotfiles.

The system-state backup intentionally excludes NetworkManager credentials.
