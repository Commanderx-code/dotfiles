# Palettes are the JSON files in configs/themes.
function __rice_palettes
    set -q DOTFILES_DIR; or return
    for file in $DOTFILES_DIR/configs/themes/*.json
        path change-extension '' (path basename -- $file)
    end
end

complete -c rice -f
complete -c rice -n __fish_use_subcommand -a show -d 'Colour swatches for a palette'
complete -c rice -n __fish_use_subcommand -a pick -d 'Choose from a list with a preview'
complete -c rice -n __fish_use_subcommand -a '(__rice_palettes)' -d Palette
complete -c rice -n '__fish_seen_subcommand_from show' -a '(__rice_palettes)' -d Palette
complete -c rice -l no-rebuild -d 'Write the choice without rebuilding Home Manager'
