#!/usr/bin/env fish

# Secure backup of SSH and KDE Wallet.
# The encrypted archives may be stored on an external drive.
# No secret contents are ever copied into the dotfiles repository.

umask 077

if test (count $argv) -ne 1
    echo "Usage:"
    echo "  backup-secrets /path/to/backup/folder"
    echo
    echo "Example:"
    echo "  backup-secrets /run/media/$USER/BackupDrive/secrets"
    exit 1
end

set -l DEST (string trim --right --chars=/ "$argv[1]")
set -l TIMESTAMP (date "+%Y-%m-%d_%H-%M-%S")

if not command -q gpg
    echo "Error: gpg is not installed."
    echo "Install it with:"
    echo "  sudo pacman -S gnupg"
    exit 1
end

if not command -q tar
    echo "Error: tar is not installed."
    exit 1
end

mkdir -p "$DEST"

if not test -d "$DEST"
    echo "Error: Could not create destination:"
    echo "  $DEST"
    exit 1
end

if not test -w "$DEST"
    echo "Error: Destination is not writable:"
    echo "  $DEST"
    exit 1
end

echo "==> Secure backup destination:"
echo "    $DEST"
echo

set -l BACKED_UP 0

#
# SSH
#

if test -d "$HOME/.ssh"
    set -l SSH_OUTPUT "$DEST/ssh-$TIMESTAMP.tar.gz.gpg"

    echo "==> Encrypting SSH backup"
    echo "    $SSH_OUTPUT"
    echo

    tar \
        -C "$HOME" \
        -czf - \
        .ssh \
        | gpg \
        --symmetric \
        --cipher-algo AES256 \
        --output "$SSH_OUTPUT"

    if test $pipestatus[1] -ne 0 -o $pipestatus[2] -ne 0
        echo
        echo "ERROR: SSH backup failed."
        rm -f "$SSH_OUTPUT"
        exit 1
    end

    chmod 600 "$SSH_OUTPUT"
    set BACKED_UP 1

    echo
    echo "SSH backup complete."
    echo
else
    echo "==> ~/.ssh does not exist; skipping SSH backup."
    echo
end

#
# KDE Wallet
#

set -l KWALLET "$HOME/.local/share/kwalletd"

if test -d "$KWALLET"
    set -l KWALLET_OUTPUT "$DEST/kwallet-$TIMESTAMP.tar.gz.gpg"

    echo "==> Encrypting KDE Wallet backup"
    echo "    $KWALLET_OUTPUT"
    echo

    tar \
        -C "$HOME/.local/share" \
        -czf - \
        kwalletd \
        | gpg \
        --symmetric \
        --cipher-algo AES256 \
        --output "$KWALLET_OUTPUT"

    if test $pipestatus[1] -ne 0 -o $pipestatus[2] -ne 0
        echo
        echo "ERROR: KDE Wallet backup failed."
        rm -f "$KWALLET_OUTPUT"
        exit 1
    end

    chmod 600 "$KWALLET_OUTPUT"
    set BACKED_UP 1

    echo
    echo "KDE Wallet backup complete."
    echo
else
    echo "==> KDE Wallet directory does not exist; skipping."
    echo
end

if test $BACKED_UP -eq 0
    echo "Nothing was backed up."
    exit 1
end

echo "==> Created encrypted backups:"
ls -lh "$DEST"/*"$TIMESTAMP"*.gpg 2>/dev/null

echo
echo "IMPORTANT:"
echo "  - Keep the encryption passphrase somewhere separate."
echo "  - Do NOT commit these .gpg files to your dotfiles repository."
echo "  - Test decryption before relying on this as your only backup."
echo
echo "Secure backup complete."
