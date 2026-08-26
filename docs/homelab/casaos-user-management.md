---
title: CasaOS User Management
category: Homelab
managed_by: CasaOS/ZimaOS app
source: /var/lib/casaos/apps/big-bear-casaos-user-management/docker-compose.yml
runtime: big-bear-casaos-user-management
tags: casaos users privileged security
status: active-external
criticality: sensitive
last_verified: 2026-08-26
---

# CasaOS User Management

## Purpose

Big Bear CasaOS User Management is installed as a privileged CasaOS/ZimaOS application.

## Port

```text
5000
```

## Privileges

The app has extensive host privileges including:

```text
privileged: true
SYS_ADMIN
seccomp: unconfined
```

and bind mounts host system areas including:

```text
/sys/fs/cgroup
/var/lib/casaos/db
/run/systemd/system
/var/run/dbus/system_bus_socket
```

## Credentials

The Compose definition contains an administrator username/password environment configuration.

🛑 The password value is intentionally not reproduced in this Bible.

Do not commit the live Compose definition to a public repository without sanitizing credentials.

## Security Importance

Because this container can interact deeply with CasaOS/systemd and is privileged, restrict its web UI to trusted users and networks.
