---
title: Tugtainer
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/tugtainer/compose.yaml
runtime: tugtainer + tugtainer-socket-proxy
tags: tugtainer docker management socket-proxy
status: active
criticality: important
last_verified: 2026-08-26
---

# Tugtainer

## Purpose

Tugtainer provides Docker/container management through a dedicated socket-proxy architecture rather than mounting the Docker socket directly into the main Tugtainer container.

## Containers

```text
tugtainer
tugtainer-socket-proxy
```

## Port

```text
9412 -> 80
```

## Docker Access

Tugtainer connects through:

```text
DOCKER_HOST=tcp://socket-proxy:2375
```

The socket proxy mounts:

```text
/var/run/docker.sock:/var/run/docker.sock:ro
```

## Proxy Permissions

The proxy enables Docker API areas including:

```text
CONTAINERS
EVENTS
IMAGES
INFO
NETWORKS
PING
POST
VERSION
```

## Persistence

Named volume:

```text
tugtainer_data:/tugtainer
```

## Secret Handling

The stack uses an `AGENT_SECRET` from environment configuration.

🛑 Do not place the real secret value in public documentation or Git.

## Protection Labels

Both containers use:

```text
dev.quenary.tugtainer.protected=true
```

## Update

```bash
cd /DATA/compose/tugtainer
docker compose pull
docker compose up -d
```
