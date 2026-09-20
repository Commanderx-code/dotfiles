function zdev --description 'Open the Commander editor, Fish and Git workspace here'
    if test (count $argv) -gt 0
        printf 'Usage: zdev (run from the project directory)\n' >&2
        return 2
    end
    if set -q ZELLIJ
        command zellij action new-tab --layout commander-dev --cwd "$PWD"
    else
        command zellij --layout commander-dev
    end
end
