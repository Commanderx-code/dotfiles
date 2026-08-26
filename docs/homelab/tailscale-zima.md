---
title: Tailscale on ZimaBoard
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/tailscale/compose.yaml
runtime: tailscale container
tags: tailscale subnet-router remote-access docker
status: active
criticality: important
last_verified: 2026-08-26
---

# Tailscale on ZimaBoard

## Container

```text
tailscale
```

## Network

```text
network_mode: host
```

## Privileges / Capabilities

```text
privileged: true
NET_ADMIN
NET_RAW
/dev/net/tun
```

## Advertised Route

```text
192.168.50.0/24
```

Configured through:

```text
TS_ROUTES=192.168.50.0/24
```

## State

```text
/DATA/AppData/tailscale
  -> /var/lib/tailscale
```

## Web Interface

The entrypoint starts:

```text
tailscaled
```

then:

```text
tailscale web --listen 0.0.0.0:5252
```

Port 5252 is therefore exposed via host networking.

## Duplicate Definition

Batch 5 also contains a CasaOS/ZimaOS Tailscale definition under:

```text
/var/lib/casaos/apps/tailscale
```

The current `/DATA/compose/tailscale` stack mirrors that design.

Confirm only one container instance owns the name `tailscale`.
