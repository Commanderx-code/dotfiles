---
title: ZimaBoard Container Troubleshooting
category: Troubleshooting
managed_by: Documentation
source: /DATA/compose
runtime: ZimaBoard
tags: docker compose dockge zima troubleshooting
status: active
criticality: important
last_verified: 2026-08-26
---

# ZimaBoard Container Troubleshooting

## Docker Permission Denied

Check:

```bash
docker ps
```

If access to `/var/run/docker.sock` is denied, inspect group membership:

```bash
id
ls -l /var/run/docker.sock
```

Avoid making the Docker socket world-writable.

## Stack Won't Start

```bash
cd /DATA/compose/STACK
docker compose config
docker compose ps
docker compose logs --tail=200
```

## Port Conflict

```bash
sudo ss -lntup
```

Then look for the published port.

## Duplicate Container Name

This can happen when both a CasaOS definition and `/DATA/compose` definition exist for the same service.

Examples in Batch 5 include:

- Glances
- Tailscale

Check:

```bash
docker ps -a --format '{{.Names}}'
```

and decide which management layer owns the service.

## Missing Persistent Data

Inspect mounts:

```bash
docker inspect CONTAINER
```

or:

```bash
docker compose config
```

Make sure `/DATA/AppData/...` exists before recreating the container.

## Environment / Secret Problems

Several stacks have `.env` files.

Check variable names without printing secret values:

```bash
grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | cut -d= -f1
```

Never paste full secrets into the Bible or a public Git repository.
