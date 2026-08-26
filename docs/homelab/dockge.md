---
title: Dockge
category: Homelab
managed_by: CasaOS/ZimaOS app
source: /var/lib/casaos/apps/big-bear-dockge/docker-compose.yml
runtime: dockge container
tags: dockge docker compose management
status: active
criticality: important
last_verified: 2026-08-26
---

# Dockge

## Purpose

Dockge is the main UI for managing Docker Compose stacks under:

```text
/DATA/compose
```

## Container

```text
dockge
```

## Port

```text
5001
```

## Important Environment

```text
DOCKGE_STACKS_DIR=/DATA/compose
```

## Volumes

```text
/var/run/docker.sock
  -> /var/run/docker.sock

/DATA/AppData/big-bear-dockge/data
  -> /app/data

/DATA/compose
  -> /DATA/compose
```

## Why It Is Useful

Dockge gives a UI for:

- viewing stack status
- editing Compose
- starting/stopping stacks
- viewing logs
- managing stacks from one place

## Security Note

Dockge has direct access to the Docker socket. Restrict access to the Dockge UI to trusted users/network segments.

## Recovery

Restore:

```text
/DATA/AppData/big-bear-dockge/data
/DATA/compose
```

then recreate the Dockge container from its CasaOS/ZimaOS definition.
