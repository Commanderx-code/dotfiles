function rgi --description 'Search with ripgrep, pick a match in fzf and open it in an editor'
    if test (count $argv) -eq 0
        echo 'Usage: rgi <pattern> [ripgrep options or paths]' >&2
        return 1
    end
    set -l pick (rg --with-filename --line-number --no-heading --color=always $argv \
        | fzf --ansi --delimiter ':' \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window 'right,60%,wrap')
    test -n "$pick"; or return 0
    # A match reads file:line:text.
    set -l parts (string split --max 2 ':' -- (string replace -ra '\e\[[0-9;]*m' '' -- "$pick"))
    string match -qr '^[1-9][0-9]*$' -- "$parts[2]"; or return 1
    set -l editor (__commander_editor); or return
    $editor "+$parts[2]" -- "$parts[1]"
end
