---
title: Glances
category: Homelab
managed_by: Docker Compose + CasaOS/ZimaOS
source: /DATA/compose/glances/compose.yaml
runtime: glances container
tags: glances monitoring docker zimaboard
status: active-duplicate-definition
criticality: normal
last_verified: 2026-08-26
---

# Glances

## Purpose

Glances provides host/container monitoring with its web interface enabled.

## Container

```text
glances
```

## Image

```text
nicolargo/glances:4.5.4
```

## Environment

```text
GLANCES_OPT=-w
```

## Ports

```text
61208
61209
```

## Host Visibility

The container uses:

```text
pid: host
```

and mounts:

```text
/var/run/docker.sock
/mnt
/DATA
```

## Resource Reservation

```text
256M
```

## Duplicate Definition

Batch 5 contains both:

```text
/DATA/compose/glances/compose.yaml
/var/lib/casaos/apps/glances/docker-compose.yml
```

This means Glances has both a Compose-stack definition and a CasaOS/ZimaOS app definition.

Before deleting either definition, confirm which management layer currently owns the running container.
