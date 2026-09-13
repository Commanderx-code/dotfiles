#!/usr/bin/env fish
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1
set -l reporter (path dirname (status filename))/backup-health.py
if not test -f "$reporter"
    set reporter "$HOME/.local/share/dotfiles/backup-health.py"
end
python3 "$reporter" $argv
