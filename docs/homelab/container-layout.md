---
title: Container Directory Layout
category: Homelab
managed_by: Docker / Dockge
source: /DATA/compose
runtime: /DATA
tags: docker compose appdata layout dockge
status: active
criticality: important
last_verified: 2026-08-26
---

# Container Directory Layout

## Canonical Stack Layout

```text
/DATA/compose/<stack>/compose.yaml
```

Examples:

```text
/DATA/compose/homepage/compose.yaml
/DATA/compose/homeassistant/compose.yaml
/DATA/compose/tailscale/compose.yaml
```

## Persistent Data

Prefer:

```text
/DATA/AppData/<application>/
```

for bind-mounted application state.

Examples:

```text
/DATA/AppData/homepage/config
/DATA/AppData/homeassistant/config
/DATA/AppData/tailscale
/DATA/AppData/mosquitto
/DATA/AppData/zigbee2mqtt
```

## Why This Matters

This split makes recovery clearer:

```text
compose.yaml  -> how to launch the service
AppData       -> the service's persistent state
```

Both are required for a complete migration.

## Dockge

Dockge points its stacks directory at:

```text
/DATA/compose
```

so stacks stored there can be managed directly from Dockge.

## CasaOS / ZimaOS

Store-managed applications live under:

```text
/var/lib/casaos/apps
```

These are separate from the preferred `/DATA/compose` convention.
