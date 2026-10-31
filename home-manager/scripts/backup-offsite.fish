#!/usr/bin/env fish

# Personal files to the offsite Restic repository (Backblaze B2 over its S3 API).
# The repository URL comes from machine.json; the repository password and the S3
# credentials live in KDE Wallet next to the local repository's password.
#
#   backup-offsite          back up now (the daily timer runs this)
#   backup-offsite --setup  store credentials in the wallet and initialize the repository

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

if not set -q OFFSITE_REPOSITORY
    echo "Offsite backup is not configured."
    echo "Add offsiteRepository to machine.json, for example:"
    echo '  "offsiteRepository": "s3:https://s3.us-west-004.backblazeb2.com/<bucket>/garuda-home"'
    exit 0
end

for tool in restic kwallet-query
    if not command -q $tool
        echo "Error: $tool is not installed."
        exit 1
    end
end

set -l REPO "$OFFSITE_REPOSITORY"
set -l ENTRY "$OFFSITE_WALLET_ENTRY"
set -l wallet_arguments -f "$RESTIC_WALLET_FOLDER"
set -l PASSWORD_COMMAND (string join -- " " kwallet-query -f (string escape -- "$RESTIC_WALLET_FOLDER") -r (string escape -- "$ENTRY") (string escape -- "$RESTIC_WALLET"))

function read_entry --no-scope-shadowing
    kwallet-query $wallet_arguments -r "$argv[1]" "$RESTIC_WALLET" 2>/dev/null
end

if contains -- --setup $argv
    echo "==> Offsite repository setup"
    echo "    Repository: $REPO"
    echo
    echo "Create a private bucket in Backblaze B2 with lifecycle rule 'Keep only the"
    echo "last version', then an application key restricted to that bucket with"
    echo "read, write, list and delete access. Enter that key here."
    echo
    read -P 'S3 key ID: ' key_id
    read --silent -P 'S3 application key: ' key_secret
    echo
    if not string match -qr '^[A-Za-z0-9]+$' -- "$key_id"; or not string match -qr '^[A-Za-z0-9+/=_-]+$' -- "$key_secret"
        echo "Error: unexpected characters in the key; nothing was saved."
        exit 1
    end
    set -l existing (read_entry "$ENTRY")
    if test -n "$existing"
        echo "The wallet already holds a repository password in '$ENTRY'; keeping it."
        set -l password "$existing"
    else
        set -l password (head -c 32 /dev/urandom | base64 | string trim)
        printf '%s' "$password" | kwallet-query $wallet_arguments -w "$ENTRY" "$RESTIC_WALLET"; or exit 1
    end
    printf '%s' "$key_id" | kwallet-query $wallet_arguments -w "$ENTRY-key-id" "$RESTIC_WALLET"; or exit 1
    printf '%s' "$key_secret" | kwallet-query $wallet_arguments -w "$ENTRY-key" "$RESTIC_WALLET"; or exit 1
    set -e key_secret
    set -x AWS_ACCESS_KEY_ID "$key_id"
    set -x AWS_SECRET_ACCESS_KEY (read_entry "$ENTRY-key")
    echo
    if restic --repo "$REPO" --password-command "$PASSWORD_COMMAND" cat config >/dev/null 2>&1
        echo "Repository already initialized; credentials updated."
    else
        restic --repo "$REPO" --password-command "$PASSWORD_COMMAND" init; or exit 1
    end
    echo
    echo "Store the repository password somewhere off this machine (password manager"
    echo "or printed sheet). Without it the offsite data cannot be read:"
    echo "  kwallet-query -f $RESTIC_WALLET_FOLDER -r $ENTRY $RESTIC_WALLET"
    exit 0
end

# One offsite job at a time. OFFSITE_LOCK_HELD marks a caller that already holds
# this lock. The local drive's backup uses its own lock and may run alongside.
set -l LOCK "$XDG_RUNTIME_DIR/backup-offsite.lock"
if not set -q OFFSITE_LOCK_HELD; and set -q XDG_RUNTIME_DIR; and command -q flock
    if not flock --nonblock "$LOCK" true
        echo "Another offsite backup or repository check is running; waiting for it to finish..."
    end
    set -x OFFSITE_LOCK_HELD 1
    exec flock "$LOCK" fish --no-config (status filename) $argv
end

echo "==> Offsite backup"
echo "    Repository: $REPO"
echo

if command -q nm-online; and not nm-online -q -t 60
    echo "No network connection; the offsite backup waits for the next run."
    exit 0
end

set -x AWS_ACCESS_KEY_ID (read_entry "$ENTRY-key-id")
set -x AWS_SECRET_ACCESS_KEY (read_entry "$ENTRY-key")
if test -z "$AWS_ACCESS_KEY_ID"; or test -z "$AWS_SECRET_ACCESS_KEY"
    echo "Error: no S3 credentials in the wallet. Run: backup-offsite --setup"
    exit 1
end

set -l paths_file (path dirname (status filename))/lib/backup-paths.fish
if not test -f "$paths_file"
    set paths_file "$HOME/.local/share/dotfiles/backup-paths.fish"
end
source "$paths_file"; or exit 1
set -l EXISTING $BACKUP_PATHS

if test (count $EXISTING) -eq 0
    echo "Error: No backup paths exist."
    exit 1
end

echo "==> Backing up:"
for path in $EXISTING
    echo "    $path"
end
echo

# Downloads, build output, dependency caches and files over 1 GiB (rescue media
# images and release archives) stay local: they are large, churn, and are easy
# to download or build again. --exclude-caches skips every directory marked
# with CACHEDIR.TAG, which covers Cargo's registry and target directories.
restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    backup \
    --exclude-caches \
    --exclude-larger-than 1G \
    --exclude "$HOME/Downloads" \
    --exclude "**/node_modules" \
    --exclude "$DOTFILES_DIR/.system-backup-capture-*" \
    --exclude "$DOTFILES_DIR/.system-backup.lock" \
    $EXISTING

if test $status -ne 0
    echo
    echo "ERROR: Offsite Restic backup failed."
    exit 1
end

echo
echo "==> Recent snapshots"

restic \
    --repo "$REPO" \
    --password-command "$PASSWORD_COMMAND" \
    snapshots \
    --latest 3

if test $status -ne 0
    echo
    echo "ERROR: Could not list recent snapshots."
    exit 1
end

echo
set -l recorder (path dirname (status filename))/restic-job.py
if not test -f "$recorder"
    set recorder "$HOME/.local/bin/restic-job"
end
python3 "$recorder" record-backup --offsite; or exit 1

echo "Offsite backup complete."
