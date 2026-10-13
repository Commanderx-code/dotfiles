function fdi --description 'Pick a file with fzf and open it in an editor'
    set -l file (fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'bat --color=always --style=numbers --line-range :300 {}' --preview-window 'right,60%,wrap')
    test -n "$file"; or return 0
    set -l editor (__commander_editor); or return
    $editor -- "$file"
end
