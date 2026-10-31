# Personal directories that every Restic repository receives. Source it after
# lib/settings.fish; it sets BACKUP_PATHS to the entries that exist right now
# and BACKUP_EXCLUDE_PATTERNS to the paths both repositories leave out.
#
# Applications can register additional repositories without coupling this file
# to their code. Each file in ~/.config/backup-personal/paths.d/ contains
# absolute paths, one per line; # starts a comment.

set -l candidates \
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
    "$HOME/.cargo" \
    "$HOME/.claude"

set -l config_home "$HOME/.config"
set -q XDG_CONFIG_HOME; and set config_home "$XDG_CONFIG_HOME"
set -l paths_directory "$config_home/backup-personal/paths.d"
if test -d "$paths_directory"
    for registration in "$paths_directory"/*
        test -f "$registration"; or continue
        while read -l extra_path
            test -n "$extra_path"; or continue
            string match -q '#*' -- "$extra_path"; and continue
            if not string match -q '/*' -- "$extra_path"
                printf 'Backup registration must use an absolute path: %s\n' "$registration" >&2
                exit 1
            end
            contains -- "$extra_path" $candidates; or set -a candidates "$extra_path"
        end < "$registration"
    end
end

set -g BACKUP_PATHS
for path in $candidates
    test -e "$path"; and set -ga BACKUP_PATHS "$path"
end

# Login tokens stay out of Restic; backup-secrets covers credentials separately.
# Callers expand this as --exclude=$BACKUP_EXCLUDE_PATTERNS, one option per entry.
set -g BACKUP_EXCLUDE_PATTERNS "$HOME/.claude/.credentials.json" "$HOME/.cargo/credentials*"
