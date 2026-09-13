function dotfiles-settings --description "Load shared workstation settings"
    set -l helper "$HOME/.local/share/dotfiles/settings.fish"
    if not test -f "$helper"
        set helper (path resolve (path dirname (status filename))/../../../home-manager/scripts/lib/settings.fish)
    end
    source "$helper"
end
