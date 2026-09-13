#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l REPO "$RESTIC_REPOSITORY"
set -l PASSWORD_COMMAND (string join " " kwallet-query -f (string escape -- "$RESTIC_WALLET_FOLDER") -r (string escape -- "$RESTIC_WALLET_ENTRY") (string escape -- "$RESTIC_WALLET"))

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
    echo "Make sure $BACKUP_MOUNT is unlocked and mounted."
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
    "$HOME/github" \
    "$HOME/Applications" \
    "$DOTFILES_DIR" \
    "$CONFIG_BIBLE_HOME" \
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
    backup \
    --exclude "$DOTFILES_DIR/.system-backup-capture-*" \
    --exclude "$DOTFILES_DIR/.system-backup.lock" \
    $EXISTING

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
set -l recorder (path dirname (status filename))/restic-job.py
if not test -f "$recorder"
    set recorder "$HOME/.local/bin/restic-job"
end
python3 "$recorder" record-backup; or exit 1

echo "Personal backup complete."
