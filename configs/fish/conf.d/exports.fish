# Environment and executable paths. Integrations are owned by Home Manager.
for directory in DATA CONFIG STATE CACHE
    set -l variable XDG_{$directory}_HOME
    if not set -q $variable
        switch $directory
            case DATA
                set -gx $variable "$HOME/.local/share"
            case CONFIG
                set -gx $variable "$HOME/.config"
            case STATE
                set -gx $variable "$HOME/.local/state"
            case CACHE
                set -gx $variable "$HOME/.cache"
        end
    end
end

set -gx BAT_PAGER ""
set -gx EDITOR nvim
set -gx VISUAL nvim

# Each existing directory is prepended, retaining the previous priority order.
for directory in "$HOME/.local/bin" "$HOME/.cargo/bin" \
        /var/lib/flatpak/exports/bin "$HOME/.local/share/flatpak/exports/bin" /snap/bin
    if test -d "$directory"
        fish_add_path -g "$directory"
    end
end

# Let Homebrew configure its own environment and paths once.
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
end

# Export per-shell defaults without rewriting Fish's universal variables.
set -q GOPATH; or set -gx GOPATH "$HOME/go"
set -q GOBIN; or set -gx GOBIN "$GOPATH[1]/bin"
for directory in /usr/local/go/bin "$GOBIN"
    if test -d "$directory"
        fish_add_path -g "$directory"
    end
end

# Shared workstation settings.
dotfiles-settings
