#!/usr/bin/env fish
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1
set -l helper (path dirname (status filename))/encrypted-backup.py
if not test -f "$helper"
    set helper "$HOME/.local/share/dotfiles/encrypted-backup.py"
end
exec python3 "$helper" "$BACKUP_MOUNT/secrets" --credential-only $argv
