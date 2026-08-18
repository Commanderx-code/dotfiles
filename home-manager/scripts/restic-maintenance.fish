#!/usr/bin/env fish

set -l MOUNT "/run/media/$USER/Linux-Backup"
set -l REPO "$MOUNT/restic"
set -l PASSWORD_COMMAND "kwallet-query -f Restic -r Crucial-X6 kdewallet"
set -l LOCK "$XDG_RUNTIME_DIR/restic-maintenance.lock"

echo "==> Restic maintenance"
echo "    Repository: $REPO"
echo

if not mountpoint -q "$MOUNT"
    echo "Linux-Backup is not mounted. Nothing to do."
    exit 0
end

if not test -d "$REPO"
    echo "Restic repository not found:"
    echo "  $REPO"
    exit 0
end

if not command -q restic
    echo "Error: restic is not installed."
    exit 1
end

if not command -q kwallet-query
    echo "Error: kwallet-query is not installed."
    exit 1
end

flock -n "$LOCK" restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    forget \
    --keep-daily 7 \
    --keep-weekly 5 \
    --keep-monthly 12 \
    --keep-yearly 3 \
    --prune

if test $status -ne 0
    echo
    echo "Restic retention/prune failed."
    exit 1
end

echo
echo "==> Standard repository check"

restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    check

if test $status -ne 0
    echo
    echo "Repository check failed."
    exit 1
end

echo
echo "Restic maintenance complete."
