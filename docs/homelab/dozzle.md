---
title: Dozzle
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/dozzle/compose.yaml
runtime: dozzle container
tags: dozzle logs docker
status: active
criticality: normal
last_verified: 2026-08-26
---

# Dozzle

## Purpose

Dozzle provides a web UI for viewing Docker container logs.

## Container

```text
dozzle
```

## Port

```text
8888 -> 8080
```

## Docker Access

```text
/var/run/docker.sock
  -> /var/run/docker.sock
```

## Persistence

Named volume:

```text
dozzle_data:/data
```

## Hostname Label

```text
DOZZLE_HOSTNAME=Zima
```

## Security

Because Dozzle reads from the Docker socket, restrict access to trusted users/networks.

## Update

```bash
cd /DATA/compose/dozzle
docker compose pull
docker compose up -d
```
