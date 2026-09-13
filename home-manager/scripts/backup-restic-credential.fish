#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l MOUNT "$BACKUP_MOUNT"
set -l DEST "$MOUNT/secrets"
set -l WALLET "$RESTIC_WALLET"
set -l FOLDER "$RESTIC_WALLET_FOLDER"
set -l ENTRY "$RESTIC_WALLET_ENTRY"

echo "========================================"
echo " Restic recovery credential backup"
echo "========================================"
echo

if not mountpoint -q "$MOUNT"
    echo "Error: $MOUNT is not mounted."
    exit 1
end

if not command -q kwallet-query
    echo "Error: kwallet-query is not installed."
    exit 1
end

if not command -q gpg
    echo "Error: gpg is not installed."
    exit 1
end

mkdir -p "$DEST"

set -l RESTIC_PASSWORD (
    kwallet-query \
        -f "$FOLDER" \
        -r "$ENTRY" \
        "$WALLET"
)

if test $status -ne 0
    echo "Error: Could not retrieve the Restic password from KWallet."
    exit 1
end

if test -z "$RESTIC_PASSWORD"
    echo "Error: KWallet returned an empty Restic password."
    exit 1
end

set -l TIMESTAMP (date "+%Y-%m-%d_%H-%M-%S")
set -l OUTPUT "$DEST/restic-password-$TIMESTAMP.txt.gpg"

echo "The Restic password will now be encrypted with GPG."
echo
echo "IMPORTANT:"
echo "Use a recovery passphrase you will remember."
echo "Do not use the Restic password itself as the GPG passphrase."
echo

printf '%s\n' "$RESTIC_PASSWORD" | \
    gpg \
        --symmetric \
        --cipher-algo AES256 \
        --output "$OUTPUT"

set -l GPG_STATUS $status

# Explicitly remove the variable from the Fish process.
set -e RESTIC_PASSWORD

if test $GPG_STATUS -ne 0
    echo
    echo "ERROR: GPG encryption failed."
    rm -f "$OUTPUT"
    exit 1
end

chmod 600 "$OUTPUT"

echo
echo "Encrypted recovery credential created:"
echo "  $OUTPUT"
echo
echo "No plaintext Restic password was written to disk."
echo
echo "Recovery command:"
echo "  gpg --decrypt \"$OUTPUT\""
echo
echo "Restic credential backup complete."
