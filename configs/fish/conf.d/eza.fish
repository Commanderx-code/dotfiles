# ---------------------------------------------------------
# EZA - Modern ls Replacement
# ---------------------------------------------------------

# Colours come from ~/.config/eza/theme.yml, generated from the palette
# chosen with `rice` (home-manager/modules/theme.nix).
# An EZA_COLORS left from the earlier version of this file overrides that theme.
# It was set as a universal variable, which outlives the config that set it,
# so it is erased here if it is still around.
if set -q EZA_COLORS
    set --erase EZA_COLORS
end

# Replacements
alias ls="eza --icons --group-directories-first --colour=always"
alias ll="eza -lh --icons --group-directories-first --time-style=long-iso"
alias la="eza -lha --icons --group-directories-first"
alias tree="eza --tree --level=2 --icons"

# Sort variations
alias lx="eza -lh --sort=extension --icons"
alias lk="eza -lh --sort=size --icons"
alias lt="eza -lh --sort=modified --icons"

# Directories / files only
alias ldir="eza -l --icons --only-dirs"
alias lf="eza -l --icons --only-files"

alias lgit="eza -l --git --icons"
alias l1="eza -1 --icons"
alias lr="eza -R --icons"
