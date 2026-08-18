#!/usr/bin/env fish

set -l MOUNT "/run/media/$USER/Linux-Backup"
set -l REPO "$MOUNT/restic"
set -l LOCK "$XDG_RUNTIME_DIR/backup-personal.lock"
set -l STAMP "$XDG_RUNTIME_DIR/backup-on-mount.stamp"

# Give Plasma/udisks time to finish unlocking and mounting.
for i in (seq 1 15)
    if mountpoint -q "$MOUNT"; and test -d "$REPO"
        break
    end

    sleep 2
end

# Ignore unrelated changes under /run/media/$USER.
if not mountpoint -q "$MOUNT"
    exit 0
end

if not test -d "$REPO"
    exit 0
end

# Avoid duplicate triggers within five minutes.
if test -f "$STAMP"
    set -l now (date +%s)
    set -l last (stat -c %Y "$STAMP" 2>/dev/null)

    if test -n "$last"
        if test (math "$now - $last") -lt 300
            exit 0
        end
    end
end

touch "$STAMP"

# Never allow two personal backups to run simultaneously.
flock -n "$LOCK" "$HOME/.local/bin/backup-personal"
