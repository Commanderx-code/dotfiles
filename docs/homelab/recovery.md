---
title: ZimaBoard Container Recovery
category: Recovery
managed_by: Docker / Dockge / CasaOS
source: /DATA/compose + /DATA/AppData
runtime: ZimaBoard
tags: homelab recovery docker restore zimaboard
status: active
criticality: critical
last_verified: 2026-08-26
---

# ZimaBoard Container Recovery

## Recovery Priority

Preserve these in this order:

```text
1. /DATA/compose
2. /DATA/AppData
3. secrets / .env values
4. /var/lib/casaos/apps definitions when still CasaOS-managed
5. service-specific exports/backups
```

## Rebuild Pattern

For a Dockge-managed stack:

```bash
cd /DATA/compose/STACK
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100
```

## Restore Persistence First

Before `docker compose up -d`, restore bind-mounted AppData to the exact expected paths.

Examples:

```text
Homepage       /DATA/AppData/homepage/config
Home Assistant /DATA/AppData/homeassistant/config
Tailscale      /DATA/AppData/tailscale
Mosquitto      /DATA/AppData/mosquitto
Zigbee2MQTT    /DATA/AppData/zigbee2mqtt
```

## Named Volumes

Some services use Docker named volumes, including Tugtainer and Dozzle.

Named volumes require separate backup/restore treatment if they contain important state.

Check:

```bash
docker volume ls
docker volume inspect VOLUME
```

## Ownership / Permissions

After copying AppData, verify ownership/permissions expected by each container.

Do not recursively `chmod 777` AppData as a generic fix.

## Validate

```bash
docker ps
docker compose ps
docker compose logs -f
```

Then test each web UI/service from the network.

## DNS Special Case

Before starting AdGuard Home, make sure host port 53 is free:

```bash
sudo ss -lntup | grep ':53 '
```

## Docker Socket Services

Dockge, Glances, Dozzle, and Tugtainer's proxy can access Docker host information/control. Restore these only on a trusted host.
