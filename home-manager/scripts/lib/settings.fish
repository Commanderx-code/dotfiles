# Shared defaults for both repository scripts and installed commands.
# Environment overrides are useful for recovery and fixture tests.
if not set -q DOTFILES_MACHINE_CONFIG
    set -l adjacent (path resolve (path dirname (status filename))/../../machine.json)
    if test -f "$adjacent"
        set -gx DOTFILES_MACHINE_CONFIG "$adjacent"
    else
        set -l config_home "$HOME/.config"
        set -q XDG_CONFIG_HOME; and set config_home "$XDG_CONFIG_HOME"
        set -gx DOTFILES_MACHINE_CONFIG "$config_home/dotfiles/machine.json"
    end
end
if not command -q jq
    echo "dotfiles settings require jq" >&2
    return 1
end
if not test -f "$DOTFILES_MACHINE_CONFIG"
    echo "Machine settings not found: $DOTFILES_MACHINE_CONFIG" >&2
    return 1
end
set -l keys dotfilesDirectory configBibleDirectory backupMount resticRepository username wallet walletFolder walletEntry
set -l variables DOTFILES_DIR CONFIG_BIBLE_HOME BACKUP_MOUNT RESTIC_REPOSITORY HM_PROFILE RESTIC_WALLET RESTIC_WALLET_FOLDER RESTIC_WALLET_ENTRY
for i in (seq (count $keys))
    if not set -q $variables[$i]
        set -l value (jq -er --arg key "$keys[$i]" '.[$key] | select(type == "string" and length > 0)' "$DOTFILES_MACHINE_CONFIG")
        or return 1
        set -gx $variables[$i] "$value"
    end
end
