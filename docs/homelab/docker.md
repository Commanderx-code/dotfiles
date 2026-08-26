---
title: Docker on ZimaBoard
category: Homelab
managed_by: Docker Engine
source: /DATA/compose
runtime: Docker daemon
tags: docker compose containers zimaboard
status: active
criticality: critical
last_verified: 2026-08-26
---

# Docker on ZimaBoard

## Role

Docker is the container runtime for the homelab.

## Core Commands

```bash
docker ps
docker ps -a
docker images
docker network ls
docker volume ls
```

Inspect:

```bash
docker inspect CONTAINER
```

Logs:

```bash
docker logs -f CONTAINER
```

Resource usage:

```bash
docker stats
```

## Compose

From a stack directory:

```bash
docker compose ps
docker compose logs -f
docker compose pull
docker compose up -d
docker compose down
```

## Docker Socket

Several management/monitoring containers access:

```text
/var/run/docker.sock
```

Examples include:

- Dockge
- Glances
- Dozzle
- Tugtainer socket proxy

Docker socket access is security-sensitive because it can provide broad control over the Docker host.

## Recovery

A Docker service generally needs:

1. Compose definition
2. bind-mounted AppData
3. named volumes, if any
4. external secrets/environment values
5. network-specific settings
