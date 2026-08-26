---
title: Zigbee2MQTT + Mosquitto
category: Homelab
managed_by: Docker Compose / Dockge
source: /DATA/compose/zigbee/compose.yaml
runtime: mosquitto + zigbee2mqtt containers
tags: zigbee mqtt mosquitto zigbee2mqtt home-assistant
status: active
criticality: critical
last_verified: 2026-08-26
---

# Zigbee2MQTT + Mosquitto

## Stack

```text
/DATA/compose/zigbee
```

## Mosquitto

Container:

```text
mosquitto
```

Image:

```text
eclipse-mosquitto:2
```

Port:

```text
1883 -> 1883
```

Persistent paths:

```text
/DATA/AppData/mosquitto/config
/DATA/AppData/mosquitto/data
/DATA/AppData/mosquitto/log
```

## Zigbee2MQTT

Container:

```text
zigbee2mqtt
```

Image:

```text
koenkk/zigbee2mqtt:latest
```

Web UI:

```text
8081 -> 8080
```

Persistent data:

```text
/DATA/AppData/zigbee2mqtt/data
```

Dependency:

```text
zigbee2mqtt -> mosquitto
```

## Time Zone

```text
America/New_York
```

## Secret Handling

The stack has an `.env` file in Batch 5. Environment values that are credentials/secrets should remain outside public Git and documentation.

## Recovery Order

1. Restore Mosquitto config/data.
2. Restore Zigbee2MQTT data.
3. Restore the stack Compose and non-public environment values.
4. Start Mosquitto.
5. Start Zigbee2MQTT.
6. Verify Home Assistant MQTT/Zigbee entities.
