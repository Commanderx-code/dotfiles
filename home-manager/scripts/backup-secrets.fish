#!/usr/bin/env fish

# Secure backup of SSH, GnuPG, and KDE Wallet.
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

# Encrypt directly from tar's stream; plaintext archives never touch disk.
function encrypt_directory --argument-names base directory output
    set -l excludes
    if test "$directory" = .gnupg
        set excludes '--exclude=S.gpg-agent*' '--exclude=S.dirmngr' \
            '--exclude=*.lock' '--exclude=.#*' '--exclude=random_seed'
    end
    tar -C "$base" $excludes -czf - "$directory" \
        | gpg --symmetric --cipher-algo AES256 --output "$output"
    set -l result $pipestatus
    if test "$result[1]" -ne 0; or test "$result[2]" -ne 0
        echo "ERROR: Could not encrypt $directory" >&2
        rm -f -- "$output"
        return 1
    end
    chmod 600 "$output"; or return 1
end

for directory in .ssh .gnupg .local/share/kwalletd
    if not test -d "$HOME/$directory"
        echo "==> $HOME/$directory does not exist; skipping."
        continue
    end
    set -l label (path basename "$directory" | string replace -r '^\.' '')
    # Preserve the established KWallet archive name.
    test "$label" = kwalletd; and set label kwallet
    set -l output "$DEST/$label-$TIMESTAMP.tar.gz.gpg"
    echo "==> Encrypting $directory backup"
    set -l base "$HOME"
    set -l archive_directory "$directory"
    if test "$label" = kwallet
        set base "$HOME/.local/share"
        set archive_directory kwalletd
    end
    encrypt_directory "$base" "$archive_directory" "$output"; or exit 1
    set BACKED_UP 1
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
