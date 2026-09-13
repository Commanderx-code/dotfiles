function bible-secrets --description "Scan dotfiles and Config Bible for likely secrets without printing values"

    if not set -q CONFIG_BIBLE_HOME
        set -gx CONFIG_BIBLE_HOME "$HOME/github/projects/config-bible"
    end

    if not command -q rg
        echo "bible-secrets requires ripgrep"
        return 1
    end

    set -l roots "$HOME/dotfiles" "$CONFIG_BIBLE_HOME"
    set -l temp (mktemp); or return 1

    for root in $roots
        test -d "$root"; or continue
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
    end

    set -l matches (command sort -u "$temp")
    command rm -f "$temp"

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
