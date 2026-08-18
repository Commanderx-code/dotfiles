#!/usr/bin/env fish

set -l MOUNT "/run/media/$USER/Linux-Backup"
set -l SECRETS_DEST "$MOUNT/secrets"

echo "========================================"
echo " Full backup"
echo "========================================"
echo

if not mountpoint -q "$MOUNT"
    echo "Error: Linux-Backup is not mounted."
    echo
    echo "Unlock and mount the external backup drive first:"
    echo "  $MOUNT"
    exit 1
end

echo "==> 1/4 System configuration backup"
echo

backup-system-state

if test $status -ne 0
    echo
    echo "ERROR: backup-system-state failed."
    exit 1
end

echo
echo "==> Application inventory"
echo

backup-app-inventory

if test $status -ne 0
    echo
    echo "ERROR: backup-app-inventory failed."
    exit 1
end

echo
echo "==> 2/4 Personal Restic backup"
echo

backup-personal

if test $status -ne 0
    echo
    echo "ERROR: backup-personal failed."
    exit 1
end

echo
echo "==> 3/4 Encrypted secrets backup"
echo

mkdir -p "$SECRETS_DEST"

backup-secrets "$SECRETS_DEST"

if test $status -ne 0
    echo
    echo "ERROR: backup-secrets failed."
    exit 1
end

echo
echo "==> 4/4 Restic recovery credential backup"
echo

backup-restic-credential

if test $status -ne 0
    echo
    echo "ERROR: backup-restic-credential failed."
    exit 1
end

echo
echo "========================================"
echo " Backup summary"
echo "========================================"
echo

echo "System snapshot:"
echo "  $HOME/dotfiles/system-backup"
echo

echo "Personal Restic repository:"
echo "  $MOUNT/restic"
echo

echo "Encrypted secrets:"
echo "  $SECRETS_DEST"
echo

echo "Encrypted Restic recovery credential:"
command /usr/bin/ls \
    --color=never \
    -1t \
    "$SECRETS_DEST"/restic-password-*.gpg 2>/dev/null \
    | command head -n 1

echo
echo "==> Git status"
echo

git -C "$HOME/dotfiles" status --short

echo
echo "========================================"
echo " Full backup completed successfully"
echo "========================================"
echo
echo "Remember:"
echo "  System-backup changes are not pushed automatically."
echo
echo "  Review them with:"
echo "    cd ~/dotfiles"
echo "    git status"
echo
echo "  Then commit/push when ready."
