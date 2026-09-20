function fdi
    set -l file (fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'bat --color=always --style=numbers --line-range :300 {}' --preview-window 'right,60%,wrap')
    test -n "$file"; and nvim -- "$file"
end
