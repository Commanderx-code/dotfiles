function fzf_rg_search --description "Search text with ripgrep + fzf and open result in nvim"
    if not command -q rg
        echo "ripgrep not installed: sudo pacman -S ripgrep"
        return 1
    end

    if not command -q fzf
        echo "fzf not installed: sudo pacman -S fzf"
        return 1
    end

    set -l helper "$HOME/.local/bin/fzf-rg-results"
    if not test -f "$helper"
        set helper (path resolve (path dirname (status filename))/../../scripts/fzf-rg-results)
    end
    if not command -q python3; or not test -f "$helper"
        echo "Search requires python3 and fzf-rg-results" >&2
        return 1
    end

    set -l q
    read -l -P "Search text: " q

    test -z "$q"; and return 0

    set -l results (
        rg \
            --json \
            --smart-case \
            --hidden \
            --glob '!.git/*' \
            --glob '!node_modules/*' \
            --glob '!.cache/*' \
            --glob '!.local/share/Trash/*' \
            --glob '!.local/share/Steam/*' \
            -- "$q" "$PWD" "$HOME/.local/bin" 2>/dev/null |
        python3 "$helper" rows | string split0
    )
    set -l results_status $pipestatus
    if test "$results_status[2]" -ne 0
        return 1
    end

    if test (count $results) -eq 0
        echo "No matches found for: $q"
        return 0
    end

    set -l pick (
        printf '%s\0' $results |
        fzf \
            --read0 --print0 --no-multi \
            --layout=reverse \
            --border \
            --delimiter '\t' --with-nth '3..' \
            --preview="python3 "(string escape -- "$helper")" preview {1} {2}" \
            --preview-window='right,60%,nowrap' \
            --bind='ctrl-/:toggle-preview' | string split0
    )

    test (count $pick) -eq 1; or return 0
    set -l selected (printf '%s' "$pick" | python3 "$helper" decode | string split0)
    set -l selected_status $pipestatus
    test "$selected_status[2]" -eq 0; and test (count $selected) -eq 2; or return 1
    set -l file "$selected[1]"
    set -l line "$selected[2]"

    if command -q nvim
        commandline -r -- (string join ' ' -- (string escape -- nvim "+$line" -- "$file"))
        commandline -f execute
    else
        echo "$file:$line"
    end
end
