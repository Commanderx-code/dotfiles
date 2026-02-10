function fzf_rg_search --description "ripgrep -> fzf -> open match in nvim"
    if not command -q fzf
        echo "fzf not installed"
        return 1
    end
    if not command -q rg
        echo "ripgrep (rg) not installed"
        return 1
    end

    set -l q (commandline -t)
    if test -z "$q"
        echo -n "rg> "
        read -l q
    end
    test -z "$q"; and return

    set -l pick (
        rg --line-number --no-heading --smart-case --color=never -- "$q" 2>/dev/null |
        fzf --height 80% --layout=reverse --border \
            --delimiter ':' \
            --preview '__preview_file "{1}" "{2}"' \
            --preview-window='right,60%,wrap'
    )

    test -z "$pick"; and return

    set -l file (string split -m1 ':' -- $pick)[1]
    set -l line (string split -m2 ':' -- $pick)[2]

    commandline -r -- (string join ' ' -- nvim "+$line" (string escape -- $file))
    commandline -f execute
end
