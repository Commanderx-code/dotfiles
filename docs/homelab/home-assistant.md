---
title: Home Assistant
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/homeassistant/compose.yaml
runtime: homeassistant container
tags: home-assistant smart-home docker host-network
status: active
criticality: critical
last_verified: 2026-08-26
---

# Home Assistant

## Container

```text
homeassistant
```

## Image

```text
ghcr.io/home-assistant/home-assistant:stable
```

## Network

```text
network_mode: host
```

Home Assistant therefore uses the host's network stack rather than a Docker bridge port mapping.

## Privileges

```text
privileged: true
```

## Persistent Configuration

```text
/DATA/AppData/homeassistant/config
  -> /config
```

## Additional Mounts

```text
/etc/localtime:/etc/localtime:ro
/run/dbus:/run/dbus:ro
```

The D-Bus mount is useful for host/device discovery integrations.

## Time Zone

```text
America/New_York
```

## Backup

The most important application data is:

```text
/DATA/AppData/homeassistant/config
```

Also use Home Assistant's own backup/export features for an application-level recovery layer.

## Update

```bash
cd /DATA/compose/homeassistant
docker compose pull
docker compose up -d
```
