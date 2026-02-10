function fzf_open_file --description "FZF pick a file and open in nvim"
    if not command -q fzf
        echo "fzf not installed"
        return 1
    end
    if not command -q fd
        echo "fd not installed"
        return 1
    end

    set -l file (
        fd --type f --hidden --follow --exclude .git 2>/dev/null |
        fzf --height 80% --layout=reverse --border \
            --preview '__preview_file "{}"' \
            --preview-window='right,60%,wrap'
    )

    test -z "$file"; and return

    commandline -r -- (string join ' ' -- nvim (string escape -- $file))
    commandline -f execute
end
