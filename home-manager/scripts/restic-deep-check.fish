#!/usr/bin/env fish

set -l MOUNT "/run/media/$USER/Linux-Backup"
set -l REPO "$MOUNT/restic"
set -l PASSWORD_COMMAND "kwallet-query -f Restic -r Crucial-X6 kdewallet"
set -l LOCK "$XDG_RUNTIME_DIR/restic-deep-check.lock"

echo "==> Restic deep integrity check"
echo "    Repository: $REPO"
echo "    Data subset: 10%"
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
    check \
    --read-data-subset=10%

if test $status -ne 0
    echo
    echo "ERROR: Restic deep integrity check failed."
    exit 1
end

echo
echo "Deep integrity check completed successfully."
