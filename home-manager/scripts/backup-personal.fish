#!/usr/bin/env fish

set -l REPO "/run/media/$USER/Linux-Backup/restic"
set -l PASSWORD_COMMAND "kwallet-query -f Restic -r Crucial-X6 kdewallet"

echo "==> Personal backup"
echo "    Repository: $REPO"
echo

if not command -q restic
    echo "Error: restic is not installed."
    exit 1
end

if not command -q kwallet-query
    echo "Error: kwallet-query is not installed."
    exit 1
end

if not test -d "$REPO"
    echo "Error: Restic repository not found:"
    echo "  $REPO"
    echo
    echo "Make sure Linux-Backup is unlocked and mounted."
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
    "$HOME/dotfiles" \
    "$HOME/.cargo"

set -l EXISTING

for path in $PATHS
    if test -e "$path"
        set -a EXISTING "$path"
    end
end

if test (count $EXISTING) -eq 0
    echo "Error: No backup paths exist."
    exit 1
end

echo "==> Backing up:"

for path in $EXISTING
    echo "    $path"
end

echo

restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    backup $EXISTING

if test $status -ne 0
    echo
    echo "ERROR: Personal Restic backup failed."
    exit 1
end

echo
echo "==> Repository check"

restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    check

if test $status -ne 0
    echo
    echo "ERROR: Repository check failed."
    exit 1
end

echo
echo "==> Recent snapshots"

restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    snapshots \
    --latest 5

if test $status -ne 0
    echo
    echo "ERROR: Could not list recent snapshots."
    exit 1
end

echo
echo "Personal backup complete."
