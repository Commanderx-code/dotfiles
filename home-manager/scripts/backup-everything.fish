#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l MOUNT "$BACKUP_MOUNT"
set -l SECRETS_DEST "$MOUNT/secrets"

echo "========================================"
echo " Full backup"
echo "========================================"
echo

if not mountpoint -q "$MOUNT"
    echo "Error: $MOUNT is not mounted."
    echo
    echo "Unlock and mount the external backup drive first:"
    echo "  $MOUNT"
    exit 1
end

echo "==> 1/3 System configuration backup"
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
echo "==> 2/3 Personal Restic backup"
echo

backup-personal

if test $status -ne 0
    echo
    echo "ERROR: backup-personal failed."
    exit 1
end

echo
echo "==> 3/3 Encrypted secrets and recovery credential backup"
echo

mkdir -p "$SECRETS_DEST"

backup-secrets "$SECRETS_DEST" --with-restic-credential

if test $status -ne 0
    echo
    echo "ERROR: backup-secrets failed."
    exit 1
end

echo
echo "========================================"
echo " Backup summary"
echo "========================================"
echo

echo "System snapshot:"
echo "  $DOTFILES_DIR/system-backup"
echo

echo "Personal Restic repository:"
echo "  $RESTIC_REPOSITORY"
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

git -C "$DOTFILES_DIR" status --short

echo
echo "========================================"
echo " Full backup completed successfully"
echo "========================================"
echo
echo "Remember:"
echo "  System-backup changes are not pushed automatically."
echo
echo "  Review them with:"
echo "    cd $DOTFILES_DIR"
echo "    git status"
echo
echo "  Then commit/push when ready."
