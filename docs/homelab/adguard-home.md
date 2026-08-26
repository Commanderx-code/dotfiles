---
title: AdGuard Home
category: Homelab
managed_by: CasaOS/ZimaOS app
source: /var/lib/casaos/apps/adguard-home/docker-compose.yml
runtime: adguard-home container
tags: adguard dns filtering casaos
status: active-external
criticality: important
last_verified: 2026-08-26
---

# AdGuard Home

## Management

AdGuard Home currently exists as a CasaOS/ZimaOS-managed application rather than a `/DATA/compose` stack.

## Container

```text
adguard-home
```

## Image

```text
adguard/adguardhome:v0.107.76
```

## Ports

```text
3001 -> 80/tcp
853  -> 853/tcp
784  -> 784/udp
53   -> 53/tcp
53   -> 53/udp
```

## Persistent Data

```text
/DATA/AppData/adguard-home/opt/adguardhome/work
/DATA/AppData/adguard-home/opt/adguardhome/conf
```

## Network Role

Port 53 TCP/UDP means this container is configured to provide DNS directly on the ZimaBoard host address.

## Recovery

Preserve both:

```text
work
conf
```

with the CasaOS/ZimaOS app definition.

## Migration Note

If migrating this service to Dockge later, preserve the same bind-mounted data and confirm that no other DNS service is already bound to port 53.
