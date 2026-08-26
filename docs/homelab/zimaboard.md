---
title: ZimaBoard / ZimaOS
category: Homelab
managed_by: ZimaOS + Docker + Dockge/CasaOS
source: /DATA/compose + /var/lib/casaos/apps
runtime: ZimaBoard
tags: zimaboard zimaos docker casaos homelab
status: active
criticality: critical
last_verified: 2026-08-26
---

# ZimaBoard / ZimaOS

## Overview

The ZimaBoard is the main homelab host for Docker-based services.

Important filesystem conventions:

```text
Compose stacks:
  /DATA/compose/<stack>/

Persistent application data:
  /DATA/AppData/<application>/

CasaOS/ZimaOS app definitions:
  /var/lib/casaos/apps/<application>/
```

## Login Environment

The login home directory is:

```text
/DATA
```

Do not hard-code `/home/Commander` in scripts on this host. Prefer:

```bash
$HOME
$USER
$(id -gn)
```

## Primary Management Split

Two management layers exist:

```text
Dockge-managed / user-owned stacks:
  /DATA/compose

CasaOS/ZimaOS app definitions:
  /var/lib/casaos/apps
```

The long-term direction has been to move important custom stacks toward `/DATA/compose` so their Compose definitions are easy to inspect, back up, and migrate.

## Current `/DATA/compose` Stacks

```text
glances
uptimekuma
tugtainer
dozzle
homeassistant
tailscale
zigbee
homepage
```

## AppData Layout

```text
/DATA/AppData
/DATA/AppData/adguard-home
/DATA/AppData/adguard-home/opt
/DATA/AppData/big-bear-dockge
/DATA/AppData/big-bear-dockge/data
/DATA/AppData/big-bear-dockge/stacks
/DATA/AppData/big-bear-filebrowser
/DATA/AppData/big-bear-filebrowser/data
/DATA/AppData/big-bear-filebrowser/data.backup-2026-08-23-2334
/DATA/AppData/big-bear-filebrowser/database
/DATA/AppData/homeassistant
/DATA/AppData/homeassistant/config
/DATA/AppData/homepage
/DATA/AppData/homepage/config
/DATA/AppData/homepage/config.backup-20260803-033717
/DATA/AppData/homepage/config.backup-2026-08-22-0154
/DATA/AppData/intelligent_ken
/DATA/AppData/intelligent_ken/app
/DATA/AppData/mosquitto
/DATA/AppData/mosquitto/config
/DATA/AppData/mosquitto/data
/DATA/AppData/mosquitto/log
/DATA/AppData/tailscale
/DATA/AppData/tailscale.backup-2026-08-23-2343
/DATA/AppData/tailscale.backup-2026-08-23-2343/certs
/DATA/AppData/tailscale.backup-2026-08-23-2343/files
/DATA/AppData/tailscale.backup-2026-08-23-2343/profile-data
/DATA/AppData/tailscale/certs
/DATA/AppData/tailscale/files
/DATA/AppData/tailscale/profile-data
/DATA/AppData/zigbee2mqtt
/DATA/AppData/zigbee2mqtt/data
```

## Useful Docker Commands

Running containers:

```bash
docker ps
```

All containers:

```bash
docker ps -a
```

Compose stack:

```bash
cd /DATA/compose/STACK
docker compose ps
```

Logs:

```bash
docker compose logs -f
```

Restart:

```bash
docker compose restart
```

Pull/update:

```bash
docker compose pull
docker compose up -d
```

## Backup Priorities

Critical things to preserve:

1. `/DATA/compose`
2. `/DATA/AppData`
3. selected `/var/lib/casaos/apps` definitions
4. secrets stored outside Compose files
5. service-specific exports where available

## Caution

A Compose file does not necessarily contain all persistent state. Always verify the corresponding bind mounts or named volumes before migrating a service.
