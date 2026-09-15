function fish_command_not_found --description 'Find missing commands in pacman repositories and offer installation'
    printf 'fish: Unknown command: %s\n' (string escape -- "$argv[1]") >&2
    if not status is-interactive; or not command -q pkgfile; or not command -q pacman
        return 127
    end
    # Paths are not package command names; never reinterpret arguments as shell code.
    if string match -q '*/*' -- "$argv[1]"
        return 127
    end
    set -l cache "$HOME/.cache/pkgfile"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache "$XDG_CACHE_HOME/pkgfile"
    end
    set -l matches (command pkgfile --cachedir "$cache" --binaries -- "$argv[1]")
    if test $status -ne 0
        printf 'If package data is missing or outdated, refresh it with:\n  mkdir -p %s; pkgfile --cachedir %s --update\n' (string escape -- "$cache") (string escape -- "$cache") >&2
        return 127
    end
    set -l packages
    for candidate in $matches
        if string match -rq '^[A-Za-z0-9@._+:-]+/[A-Za-z0-9@._+:-]+$' -- "$candidate"
            if not contains -- "$candidate" $packages
                set -a packages "$candidate"
            end
        end
    end
    test (count $packages) -gt 0; or return 127
    printf '\nAvailable packages:\n'
    for index in (seq (count $packages))
        printf '  %s) %s\n' "$index" "$packages[$index]"
    end
    # Never consume piped input or prompt in scripts.
    isatty stdin; or return 127
    set -l choice 1
    if test (count $packages) -gt 1
        read -P 'Package number (Enter to cancel): ' choice; or return 127
        string match -rq '^[1-9][0-9]*$' -- "$choice"; or return 127
        test "$choice" -le (count $packages); or return 127
    end
    set -l package "$packages[$choice]"
    read -l -P "Install $package with pacman? [y/N] " answer; or return 127
    if contains -- "$answer" y Y yes
        command sudo pacman -S --needed -- "$package"
        if test $status -eq 0
            printf 'Installed %s. Run your command again when ready.\n' "$package"
        end
    end
    return 127
end
