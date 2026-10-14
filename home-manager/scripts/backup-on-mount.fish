#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l MOUNT "$BACKUP_MOUNT"
set -l REPO "$RESTIC_REPOSITORY"
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

# Hold the backup lock for the whole run: the backup, then maintenance and the
# deep check. A manual backup started meanwhile waits for all of it, and this
# run waits for a manual one that is already going.
if not set -q BACKUP_LOCK_HELD
    set -x BACKUP_LOCK_HELD 1
    exec flock "$LOCK" fish --no-config (status filename) $argv
end

# Avoid duplicate personal backups, but still retry overdue maintenance.
set -l recent 0
if test -f "$STAMP"
    set -l now (date +%s)
    set -l last (stat -c %Y "$STAMP" 2>/dev/null)

    if test -n "$last"
        if test (math "$now - $last") -lt 300
            set recent 1
        end
    end
end

if test $recent -eq 0
    set -l backup (path dirname (status filename))/backup-personal.fish
    if not test -f "$backup"
        set backup "$HOME/.local/bin/backup-personal"
    end
    fish --no-config "$backup"; or exit $status
    # Only successful backups start the cooldown.
    touch "$STAMP"; or exit 1
end

# Try both jobs even if one fails. Their own success dates control catch-up.
set -l failed 0
for job in restic-maintenance restic-deep-check
    set -l script (path dirname (status filename))/$job.fish
    if not test -f "$script"
        set script "$HOME/.local/bin/$job"
    end
    fish --no-config "$script" --if-due; or set failed 1
end
exit $failed
