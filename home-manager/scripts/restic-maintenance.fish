#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l runner (path dirname (status filename))/restic-job.py
if not test -f "$runner"
    set runner "$HOME/.local/bin/restic-job"
end
python3 "$runner" maintenance $argv
