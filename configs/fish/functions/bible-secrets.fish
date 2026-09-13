function bible-secrets --description "Scan dotfiles and Config Bible for likely secrets without printing values"

    dotfiles-settings; or return 1

    if not command -q rg
        echo "bible-secrets requires ripgrep"
        return 1
    end

    set -l roots "$DOTFILES_DIR" "$CONFIG_BIBLE_HOME"
    set -l temp (mktemp); or return 1

    set -l failed 0
    for root in $roots
        if not test -d "$root"
            echo "Scan directory missing: $root" >&2
            set failed 1
            continue
        end
        rg -l --hidden \
            --glob '!.git/**' \
            --glob '!node_modules/**' \
            --glob '!target/**' \
            --glob '!.venv/**' \
            --glob '!site/site/**' \
            -e '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----' \
            -e 'AKIA[0-9A-Z]{16}' \
            -e 'gh[pousr]_[A-Za-z0-9_]{20,}' \
            -e 'github_pat_[A-Za-z0-9_]{20,}' \
            -e 'sk-[A-Za-z0-9_-]{20,}' \
            "$root" 2>/dev/null >> "$temp"
        set -l scan_status $status
        if test $scan_status -gt 1
            echo "Could not completely scan: $root" >&2
            set failed 1
        end
    end

    set -l matches (command sort -u "$temp")
    set -l sort_status $status
    command rm -f "$temp"
    if test $failed -ne 0; or test $sort_status -ne 0
        echo "Secret scan incomplete; no clean result can be reported." >&2
        return 2
    end

    if test (count $matches) -eq 0
        echo "✓ No likely secrets detected"
        return 0
    end

    echo "⚠ Potential secret-bearing files:"
    for file in $matches
        echo "  $file"
    end
    echo
    echo "Values were intentionally NOT printed."
    return 1
end
