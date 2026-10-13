# The listing shortcuts (ls, ll, la, tree, ...) come from eza-shared.fish.
# Colours come from ~/.config/eza/theme.yml, generated from the palette
# chosen with `rice` (home-manager/modules/theme.nix).
# An EZA_COLORS left from the earlier version of this file overrides that theme.
# It was set as a universal variable, which outlives the config that set it,
# so it is erased here if it is still around.
if set -q EZA_COLORS
    set --erase EZA_COLORS
end
