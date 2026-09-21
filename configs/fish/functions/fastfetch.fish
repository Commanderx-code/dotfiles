function fastfetch --description 'Fit the personal Fastfetch layout to this terminal'
    # Explicit CLI options and redirected output retain native behavior.
    if test (count $argv) -gt 0; or not isatty stdout; or not command -q commander-fastfetch-layout
        command fastfetch $argv
        return $status
    end

    set -l config (command commander-fastfetch-layout --prepare | string collect)
    if test $pipestatus[1] -ne 0; or test -z "$config"
        command fastfetch
        return $status
    end

    # Detection must remain a direct Fish child: launching it from Python makes
    # Fastfetch report Python as the shell. No temporary files or resize hooks.
    printf '%s\n' "$config" | command fastfetch --config - --pipe false |
        command commander-fastfetch-layout --columns $COLUMNS --lines $LINES |
        command fastfetch --config -
    for result in $pipestatus
        if test $result -ne 0
            return $result
        end
    end
end
