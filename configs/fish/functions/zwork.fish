function zwork --description 'Pick a Zesh project/session without nesting Zellij'
    if test (count $argv) -gt 1
        printf 'Usage: zwork [directory-or-session]\n' >&2
        return 2
    end
    set -l target
    if test (count $argv) -eq 1
        set target "$argv[1]"
    else
        set -l choices (command zesh list)
        or return $status
        set target (printf '%s\n' $choices | command fzf --no-multi --prompt='Zellij project > ')
        or return 0
    end
    test -n "$target"; or return 0
    # Use repository roots on both paths so selecting a subdirectory doesn't
    # create a second, differently named session for the same project.
    if test -d "$target"
        set target (path resolve -- "$target")
        set -l root (command git -C "$target" rev-parse --show-toplevel 2>/dev/null)
        if test $status -eq 0; and test -n "$root"
            set target "$root"
        end
    end
    if not set -q ZELLIJ
        command zesh connect -- "$target"
        return $status
    end
    # Other entries are exact session names, not shell commands.
    if test -d "$target"
        set -l directory (path resolve -- "$target")
        set -l name (path basename -- "$directory")
        command zellij action switch-session --cwd "$directory" -- "$name"
    else
        command zellij action switch-session -- "$target"
    end
end
