function bible-stats --description "Show Config Bible statistics"

    dotfiles-settings; or return 1

    set -l docs "$CONFIG_BIBLE_HOME/docs"
    set -l files (command find "$docs" -type f -name '*.md' ! -name 'INDEX.md' ! -name 'INDEX-BATCH*.md' ! -name 'TEMPLATE.md' | sort)
    set -l total (count $files)
    set -l temp (mktemp -d); or return 1

    for file in $files
        command awk -F': ' '$1=="category"{sub(/^category:[[:space:]]*/,"");print;exit}' "$file" >> "$temp/categories"
        command awk -F': ' '$1=="status"{sub(/^status:[[:space:]]*/,"");print;exit}' "$file" >> "$temp/status"
        command awk -F': ' '$1=="criticality"{sub(/^criticality:[[:space:]]*/,"");print;exit}' "$file" >> "$temp/criticality"
    end

    echo
    echo "📚 Commander Config Bible"
    echo "────────────────────────────────────────"
    echo "Pages:          $total"
    echo "Critical:       "(command grep -cx 'critical' "$temp/criticality" 2>/dev/null)
    echo "Important:      "(command grep -cx 'important' "$temp/criticality" 2>/dev/null)
    echo "Planned:        "(command grep -cx 'planned' "$temp/status" 2>/dev/null)
    echo
    echo "Categories"
    echo "────────────────────────────────────────"
    command sed '/^$/d' "$temp/categories" | sort | uniq -c | sort -nr

    echo
    echo "Health"
    echo "────────────────────────────────────────"
    bible-audit --quiet
    set -l audit_status $status
    command rm -rf "$temp"
    return $audit_status
end
