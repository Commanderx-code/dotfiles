---
title: Uptime Kuma
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/uptimekuma/compose.yaml
runtime: uptimekuma container
tags: uptime kuma monitoring docker
status: active
criticality: important
last_verified: 2026-08-26
---

# Uptime Kuma

## Container

```text
uptimekuma
```

## Image

```text
louislam/uptime-kuma:2
```

## Port

```text
3002 -> 3001
```

## Persistent Data

Current bind mount:

```text
/DATA/AppData/intelligent_ken/app/data
  -> /app/data
```

## Important History

Uptime Kuma was migrated away from the older CasaOS-managed setup into `/DATA/compose/uptimekuma`.

The AppData path still retains the older generated name:

```text
intelligent_ken
```

That path is intentional in the current live Compose and should not be renamed casually without migrating the data.

## Resource Reservation

```text
128M
```

## Update

```bash
cd /DATA/compose/uptimekuma
docker compose pull
docker compose up -d
```
