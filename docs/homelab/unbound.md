---
title: Unbound
category: Homelab
managed_by: CasaOS/ZimaOS app
source: /var/lib/casaos/apps/stunning_wong/docker-compose.yml
runtime: unbound container
tags: unbound dns recursive resolver casaos
status: active-external
criticality: important
last_verified: 2026-08-26
---

# Unbound

## Container / App Name

The CasaOS generated stack is:

```text
stunning_wong
```

with service:

```text
unbound
```

## Image

```text
klutchell/unbound:latest
```

## Ports

```text
5335 -> 53/tcp
5335 -> 53/udp
```

## Intended DNS Role

Port 5335 commonly allows another local DNS service to forward recursive queries to Unbound without conflicting with port 53 on the host.

Batch 5 confirms the port mapping, but it does not contain the upstream AdGuard/Unbound application-level configuration needed to prove the exact forwarding relationship.

## Resource Settings

Reservation:

```text
512 MiB
```

CPU limit:

```text
1.00
```

## Recovery

The current CasaOS definition does not show a persistent bind mount for Unbound configuration/state. Verify whether the image is intentionally stateless or whether configuration is supplied elsewhere before rebuilding it.
