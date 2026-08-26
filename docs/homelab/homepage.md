---
title: Homepage
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/homepage/compose.yaml
runtime: homepage container
tags: homepage dashboard homelab docker
status: active
criticality: normal
last_verified: 2026-08-26
---

# Homepage

## Container

```text
homepage
```

## Port

```text
3000 -> 3000
```

## Persistent Configuration

```text
/DATA/AppData/homepage/config
  -> /app/config
```

## Allowed Hosts

The current Compose file allows:

```text
192.168.50.57:3000
homepage.home.arpa:3000
zima.home.arpa:3000
```

## Update

```bash
cd /DATA/compose/homepage
docker compose pull
docker compose up -d
```

## Logs

```bash
docker compose logs -f
```

## Recovery

Restore:

```text
/DATA/AppData/homepage/config
```

and the Compose file, then:

```bash
docker compose up -d
```
