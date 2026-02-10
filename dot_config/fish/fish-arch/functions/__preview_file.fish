function __preview_file --argument-names file line
    test -z "$file"; and return

    if test -n "$line"
        set start (math "$line - 200")
        test $start -lt 1; and set start 1
        set end (math "$line + 200")

        if command -q bat
            bat --style=numbers --color=always --line-range "$start:$end" --highlight-line "$line" "$file" 2>/dev/null
        else
            sed -n "$start,$end p" "$file" 2>/dev/null
        end
    else
        if command -q bat
            bat --style=numbers --color=always --line-range :400 "$file" 2>/dev/null
        else
            sed -n '1,400p' "$file" 2>/dev/null
        end
    end
end
