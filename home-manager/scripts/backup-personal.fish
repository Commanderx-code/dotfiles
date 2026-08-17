#!/usr/bin/env fish

set -l REPO "/run/media/$USER/Crucial X6/restic-backup"

echo "==> Personal backup"
echo "    Repository: $REPO"
echo

if not command -q restic
    echo "Error: restic is not installed."
    exit 1
end

if not test -d "$REPO"
    echo "Error: Restic repository is not available:"
    echo "  $REPO"
    echo
    echo "Make sure the Crucial X6 is mounted."
    exit 1
end

set -l PATHS \
    "$HOME/Documents" \
    "$HOME/Desktop" \
    "$HOME/Downloads" \
    "$HOME/Pictures" \
    "$HOME/Videos" \
    "$HOME/Music" \
    "$HOME/Projects" \
    "$HOME/Applications" \
    "$HOME/dotfiles"

set -l EXISTING

for path in $PATHS
    if test -e "$path"
        set -a EXISTING "$path"
    end
end

if test (count $EXISTING) -eq 0
    echo "Error: none of the configured backup paths exist."
    exit 1
end

echo "==> Backing up:"
for path in $EXISTING
    echo "    $path"
end

echo

restic \
    --repo "$REPO" \
    backup \
    $EXISTING

if test $status -ne 0
    echo
    echo "Backup failed."
    exit 1
end

echo
echo "==> Repository check"

restic \
    --repo "$REPO" \
    check

if test $status -ne 0
    echo
    echo "WARNING: backup completed, but repository check failed."
    exit 1
end

echo
echo "==> Recent snapshots"

restic \
    --repo "$REPO" \
    snapshots \
    --latest 5

echo
echo "Personal backup complete."
