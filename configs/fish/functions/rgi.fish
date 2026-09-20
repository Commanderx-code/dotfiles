function rgi
    rg --line-number --no-heading --color=always $argv \
        | fzf --ansi --delimiter ':' \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window 'right,60%,wrap'
end
