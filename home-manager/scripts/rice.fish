#!/usr/bin/env fish
# Switch the workstation's palette: terminals, prompt, editors, CLI tools and
# Plasma's colour scheme, from configs/themes/<name>.json. The SDDM login screen
# is never touched.

set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

# Overridable for recovery and fixture tests.
set -q RICE_REBUILD; or set -l RICE_REBUILD hm-rebuild

set -l themes_dir "$DOTFILES_DIR/configs/themes"
set -l selection "$DOTFILES_DIR/home-manager/rice.json"
set -l zed_settings "$DOTFILES_DIR/configs/zed/settings.json"

function __rice_usage
    echo "Usage: rice                       show the current palette and the others"
    echo "       rice show [NAME]           colour swatches (default: the current one)"
    echo "       rice pick [--no-rebuild]   choose from a list, with a swatch preview"
    echo "       rice NAME [--no-rebuild]"
    echo
    echo "Switching writes home-manager/rice.json and Zed's theme and rebuilds Home Manager."
    echo "The login screen is left alone. Commit the changed files to keep it."
end

function __rice_names --argument-names directory
    for file in $directory/*.json
        path change-extension '' (path basename $file)
    end
end

function __rice_swatches --argument-names file
    set -l title (jq -r .name $file)
    echo "$title"
    for key in (jq -r '.colors | keys_unsorted[]' $file)
        set -l hex (jq -r --arg k $key '.colors[$k]' $file)
        printf '  %s  %-8s %s\n' (set_color -b $hex; printf '      '; set_color normal) $key $hex
    end
    printf '  '
    for hex in (jq -r '.terminal.ansi[]' $file)
        set_color -b $hex
        printf '  '
    end
    set_color normal
    printf '  terminal\n'
end

# "catppuccin-mocha" -> "CommanderCatppuccinMocha", as modules/plasma.nix names it.
function __rice_scheme_name --argument-names name
    set -l words
    for word in (string split - $name)
        set -a words (string upper (string sub -l 1 $word))(string sub -s 2 $word)
    end
    echo Commander(string join '' $words)
end

argparse h/help no-rebuild -- $argv
or begin
    __rice_usage
    exit 2
end
if set -q _flag_help
    __rice_usage
    exit 0
end

set -l current (jq -er '.theme' $selection 2>/dev/null)
or begin
    echo "Cannot read the current palette from $selection" >&2
    exit 1
end

if test (count $argv) -eq 0
    echo "Current palette: $current"
    set -l nvim_override (jq -r '.nvim // empty' $selection)
    test -n "$nvim_override"; and echo "Neovim colorscheme: $nvim_override (set in rice.json)"
    echo
    for name in (__rice_names $themes_dir)
        set -l marker "  "
        test "$name" = "$current"; and set marker "* "
        printf '%s%-18s %s\n' $marker $name (jq -r .name $themes_dir/$name.json)
    end
    echo
    echo "rice pick chooses from a list; rice show NAME previews one; rice NAME switches to it."
    exit 0
end

if test "$argv[1]" = show
    set -l name $current
    test (count $argv) -ge 2; and set name $argv[2]
    if not test -f "$themes_dir/$name.json"
        echo "No palette named '$name'. Run rice to list them." >&2
        exit 1
    end
    __rice_swatches $themes_dir/$name.json
    exit 0
end

# rice pick: an fzf list of the palettes, each previewed with its swatches.
if test "$argv[1]" = pick; and test (count $argv) -eq 1
    if not command -q fzf
        echo "rice pick needs fzf; rice lists the palettes and rice NAME switches." >&2
        exit 1
    end
    set -l self (path resolve (status filename))
    # Open with the cursor on the palette in use.
    set -l position (contains -i -- $current (__rice_names $themes_dir)); or set position 1
    set -l choice (
        for name in (__rice_names $themes_dir)
            set -l marker "  "
            test "$name" = "$current"; and set marker "* "
            printf '%s\t%s%s\n' $name $marker (jq -r .name $themes_dir/$name.json)
        end | fzf --ansi --no-multi --delimiter '\t' --with-nth 2 \
            --prompt 'palette> ' --header 'Enter switch  Esc cancel  * current' \
            --bind "load:pos($position)" \
            --preview "fish $self show {1}" --preview-window 'right,55%,nowrap'
    )
    if test -z "$choice"
        echo "No palette picked; still on $current."
        exit 0
    end
    set argv (string split -f 1 \t -- $choice)
    if test "$argv[1]" = "$current"
        echo "Already on $current."
        exit 0
    end
end

set -l name $argv[1]
if test (count $argv) -gt 1; or not string match -qr '^[a-z0-9][a-z0-9-]*$' -- $name
    __rice_usage
    exit 2
end
set -l theme_file "$themes_dir/$name.json"
if not test -f "$theme_file"
    echo "No palette named '$name'. Run rice to list them." >&2
    exit 1
end

# Keep the previous choice so a failed rebuild leaves everything as it was.
set -l previous_selection (cat $selection | string collect)
set -l previous_zed ""
test -f "$zed_settings"; and set previous_zed (cat $zed_settings | string collect)

function __rice_restore --inherit-variable selection --inherit-variable zed_settings --inherit-variable previous_selection --inherit-variable previous_zed
    printf '%s\n' "$previous_selection" >$selection
    test -n "$previous_zed"; and printf '%s\n' "$previous_zed" >$zed_settings
end

# Only the palette changes; other choices in the file (such as "nvim") are kept.
jq --arg theme $name '.theme = $theme' $selection >$selection.tmp; and command mv $selection.tmp $selection
or begin
    echo "Could not write $selection" >&2
    exit 1
end

# Zed's settings are writable (Zed edits them too), so only the theme keys change.
set -l zed_theme (jq -r '.apps.zed.theme // empty' $theme_file)
if test -n "$zed_theme"; and test -f "$zed_settings"
    set -l zed_extension (jq -r '.apps.zed.extension // empty' $theme_file)
    jq --arg theme $zed_theme --arg extension "$zed_extension" '
        .theme.dark = $theme
        | if $extension != "" then .auto_install_extensions[$extension] = true else . end
    ' $zed_settings >$zed_settings.tmp
    and command cp $zed_settings.tmp $zed_settings
    command rm -f $zed_settings.tmp
end

echo "==> Palette: "(jq -r .name $theme_file)
if not set -q _flag_no_rebuild
    $RICE_REBUILD
    if test $status -ne 0
        __rice_restore
        echo
        echo "ERROR: the rebuild failed; the palette is still $current." >&2
        exit 1
    end
end

# Plasma picks the colour scheme up at the next login; apply it now when in a Plasma session.
set -l scheme (__rice_scheme_name $name)
if not set -q _flag_no_rebuild; and command -q plasma-apply-colorscheme; and string match -q '*KDE*' -- "$XDG_CURRENT_DESKTOP"
    plasma-apply-colorscheme $scheme >/dev/null
end

set -l ghostty_config "$HOME/.config/ghostty/config"
set -q XDG_CONFIG_HOME; and set ghostty_config "$XDG_CONFIG_HOME/ghostty/config"
if test -f "$ghostty_config"; and not string match -qr '^\s*theme\s*=\s*commander\s*$' -- (cat $ghostty_config)
    echo "Ghostty: set 'theme = commander' in $ghostty_config to follow the palette."
end

echo
echo "Open a new terminal to see it. To keep this palette, commit:"
echo "  home-manager/rice.json configs/zed/settings.json"
