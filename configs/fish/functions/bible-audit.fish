function bible-audit --description "Audit the Commander Config Bible against live dotfiles"
    dotfiles-settings; or return 1
    set -l repo "$DOTFILES_DIR"
    set -l docs "$CONFIG_BIBLE_HOME/docs"
    # -------------------------------------------------------------------------
    # Options
    # -------------------------------------------------------------------------

    set -l mode all
    set -l quiet 0
    set -l warnings 0

    for arg in $argv
        switch "$arg"
            case --help -h
                echo "Commander Config Bible Audit"
                echo
                echo "Usage:"
                echo "  bible-audit"
                echo "  bible-audit --functions"
                echo "  bible-audit --scripts"
                echo "  bible-audit --compose"
                echo "  bible-audit --sources"
                echo "  bible-audit --metadata"
                echo "  bible-audit --stale"
                echo "  bible-audit --quiet"
                echo
                echo "Exit status:"
                echo "  0  no actionable warnings found"
                echo "  1  warnings/errors found"
                return 0
            case --functions
                set mode functions
            case --scripts
                set mode scripts
            case --compose
                set mode compose
            case --sources
                set mode sources
            case --metadata
                set mode metadata
            case --stale
                set mode stale
            case --quiet
                set quiet 1
        end
    end

    if not test -d "$repo"
        echo "Dotfiles repository not found:"
        echo "  $repo"
        return 1
    end

    if not test -d "$docs"
        echo "Bible documentation directory not found:"
        echo "  $docs"
        return 1
    end

    set -l temp_root (mktemp -d)
    or return 1

    # -------------------------------------------------------------------------
    # 1. Fish functions
    # -------------------------------------------------------------------------

    if test "$mode" = all; or test "$mode" = functions
        if test $quiet -eq 0
            echo
            echo "── Fish functions ──"
        end

        set -l fish_dir "$repo/configs/fish/functions"
        set -l missing 0

        if test -d "$fish_dir"
            for file in "$fish_dir"/*.fish
                test -e "$file"; or continue

                set -l base (path basename "$file")
                set -l name (string replace -r '\.fish$' '' "$base")
                set -l rel "configs/fish/functions/$base"

                if not command rg -l -F "$rel" "$docs" >/dev/null 2>&1
                    if not command rg -l -F "$name" "$docs" >/dev/null 2>&1
                        echo "⚠ Undocumented Fish function: $name"
                        set missing (math $missing + 1)
                        set warnings (math $warnings + 1)
                    end
                end
            end

            if test $missing -eq 0; and test $quiet -eq 0
                echo "✓ All Fish function files appear documented"
            end
        else
            echo "⚠ Fish functions directory missing: $fish_dir"
            set warnings (math $warnings + 1)
        end
    end

    # -------------------------------------------------------------------------
    # 2. Home Manager helper scripts
    # -------------------------------------------------------------------------

    if test "$mode" = all; or test "$mode" = scripts
        if test $quiet -eq 0
            echo
            echo "── Home Manager helper scripts ──"
        end

        set -l script_dir "$repo/home-manager/scripts"
        set -l missing 0

        if test -d "$script_dir"
            for file in "$script_dir"/*
                test -f "$file"; or continue

                set -l base (path basename "$file")
                set -l name (string replace -r '\.(fish|sh)$' '' "$base")
                set -l rel "home-manager/scripts/$base"

                if not command rg -l -F "$rel" "$docs" >/dev/null 2>&1
                    if not command rg -l -F "$name" "$docs" >/dev/null 2>&1
                        echo "⚠ Undocumented Home Manager helper: $base"
                        set missing (math $missing + 1)
                        set warnings (math $warnings + 1)
                    end
                end
            end

            if test $missing -eq 0; and test $quiet -eq 0
                echo "✓ All Home Manager helper scripts appear documented"
            end
        else
            echo "⚠ Home Manager scripts directory missing: $script_dir"
            set warnings (math $warnings + 1)
        end
    end

    # -------------------------------------------------------------------------
    # 3. Compose stacks
    # -------------------------------------------------------------------------

    if test "$mode" = all; or test "$mode" = compose
        if test $quiet -eq 0
            echo
            echo "── Compose stacks ──"
        end

        set -l compose_roots

        if test -d "$repo/compose"
            set -a compose_roots "$repo/compose"
        end

        if test -d /DATA/compose
            set -a compose_roots /DATA/compose
        end

        if test (count $compose_roots) -eq 0
            if test $quiet -eq 0
                echo "✓ No local Compose root found; ZimaBoard Compose docs are external to this host"
            end
        else
            set -l missing 0

            for root in $compose_roots
                for stack in "$root"/*
                    test -d "$stack"; or continue

                    set -l name (path basename "$stack")
                    set -l has_compose 0

                    for candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml
                        if test -f "$stack/$candidate"
                            set has_compose 1
                            break
                        end
                    end

                    if test $has_compose -eq 0
                        continue
                    end

                    if not command rg -l -F "$stack" "$docs" >/dev/null 2>&1
                        if not command rg -l -F "$name" "$docs" >/dev/null 2>&1
                            echo "⚠ Undocumented Compose stack: $stack"
                            set missing (math $missing + 1)
                            set warnings (math $warnings + 1)
                        end
                    end
                end
            end

            if test $missing -eq 0; and test $quiet -eq 0
                echo "✓ All locally visible Compose stacks appear documented"
            end
        end
    end

    # -------------------------------------------------------------------------
    # 4. Validate source: metadata
    # -------------------------------------------------------------------------

    if test "$mode" = all; or test "$mode" = sources
        if test $quiet -eq 0
            echo
            echo "── Documentation source paths ──"
        end

        set -l checked 0
        set -l broken 0
        set -l reference_only 0

        for file in (command find "$docs" -type f -name '*.md' | sort)
            set -l source_path (command awk -F': ' '
                $1 == "source" {
                    sub(/^source:[[:space:]]*/, "")
                    print
                    exit
                }
            ' "$file")

            test -n "$source_path"; or continue

            # Only validate values that actually look like filesystem paths.
            # Descriptive provenance like "Prior network design" is reference
            # metadata, not a path.
            if not string match -qr '^(~?/|/)' "$source_path"
                set reference_only (math $reference_only + 1)
                continue
            end

            # Combined prose/path expressions are not single filesystem paths.
            if string match -q '* + *' "$source_path"
                set reference_only (math $reference_only + 1)
                continue
            end

            set checked (math $checked + 1)
            set -l expanded (string replace -r '^~' "$HOME" "$source_path")

            if test -e "$expanded"
                continue
            end

            # Known paths that belong to the ZimaBoard / external host.
            if string match -qr '^/DATA/' "$source_path"; or string match -qr '^/var/lib/casaos/' "$source_path"
                set reference_only (math $reference_only + 1)
                continue
            end

            set -l rel (string replace "$docs/" "" "$file")
            echo "⚠ Missing source path in $rel: $source_path"
            set broken (math $broken + 1)
            set warnings (math $warnings + 1)
        end

        if test $broken -eq 0; and test $quiet -eq 0
            echo "✓ No broken local source paths found ($checked path(s) checked, $reference_only reference/external)"
        end
    end

    # -------------------------------------------------------------------------
    # 5. Metadata audit
    # -------------------------------------------------------------------------

    if test "$mode" = all; or test "$mode" = metadata
        if test $quiet -eq 0
            echo
            echo "── Metadata ──"
        end

        set -l metadata_issues 0
        set -l title_file "$temp_root/titles.tsv"

        for file in (command find "$docs" -type f -name '*.md' \
            ! -name 'INDEX.md' \
            ! -name 'INDEX-BATCH*.md' \
            ! -name 'TEMPLATE.md' | sort)

            set -l rel (string replace "$docs/" "" "$file")

            # Legacy pages without YAML frontmatter are still real warnings,
            # but report them once instead of four warnings per file.
            set -l first_line (command head -n 1 "$file")

            if test "$first_line" != ---
                echo "⚠ Legacy page missing YAML metadata: $rel"
                set metadata_issues (math $metadata_issues + 1)
                set warnings (math $warnings + 1)
                continue
            end

            set -l title (command awk -F': ' '
                $1 == "title" {
                    sub(/^title:[[:space:]]*/, "")
                    print
                    exit
                }
            ' "$file")

            set -l category (command awk -F': ' '
                $1 == "category" {
                    sub(/^category:[[:space:]]*/, "")
                    print
                    exit
                }
            ' "$file")

            set -l status_value (command awk -F': ' '
                $1 == "status" {
                    sub(/^status:[[:space:]]*/, "")
                    print
                    exit
                }
            ' "$file")

            set -l verified (command awk -F': ' '
                $1 == "last_verified" {
                    sub(/^last_verified:[[:space:]]*/, "")
                    print
                    exit
                }
            ' "$file")

            if test -z "$title"
                echo "⚠ Missing title metadata: $rel"
                set metadata_issues (math $metadata_issues + 1)
                set warnings (math $warnings + 1)
            else
                printf '%s\t%s\n' "$title" "$rel" >>"$title_file"
            end

            if test -z "$category"
                echo "⚠ Missing category metadata: $rel"
                set metadata_issues (math $metadata_issues + 1)
                set warnings (math $warnings + 1)
            end

            if test -z "$status_value"
                echo "⚠ Missing status metadata: $rel"
                set metadata_issues (math $metadata_issues + 1)
                set warnings (math $warnings + 1)
            end

            if test -z "$verified"
                echo "⚠ Missing last_verified metadata: $rel"
                set metadata_issues (math $metadata_issues + 1)
                set warnings (math $warnings + 1)
            end
        end

        if test -s "$title_file"
            set -l duplicate_titles (
                command cut -f1 "$title_file" |
                command sort |
                command uniq -d
            )

            for title in $duplicate_titles
                echo "⚠ Duplicate documentation title: $title"
                command awk -F'\t' -v t="$title" '$1 == t { print "    " $2 }' "$title_file"
                set metadata_issues (math $metadata_issues + 1)
                set warnings (math $warnings + 1)
            end
        end

        if test $metadata_issues -eq 0; and test $quiet -eq 0
            echo "✓ Metadata looks consistent"
        end
    end

    # -------------------------------------------------------------------------
    # 6. Staleness audit
    # -------------------------------------------------------------------------

    if test "$mode" = all; or test "$mode" = stale
        if test $quiet -eq 0
            echo
            echo "── Verification age ──"
        end

        set -l stale_count 0
        set -l now (date +%s)
        set -l threshold_days 180
        set -l threshold_seconds (math "$threshold_days * 24 * 60 * 60")

        for file in (command find "$docs" -type f -name '*.md' \
            ! -name 'INDEX.md' \
            ! -name 'INDEX-BATCH*.md' \
            ! -name 'TEMPLATE.md' | sort)

            set -l verified (command awk -F': ' '
                $1 == "last_verified" {
                    sub(/^last_verified:[[:space:]]*/, "")
                    print
                    exit
                }
            ' "$file")

            test -n "$verified"; or continue

            set -l verified_epoch (date -d "$verified" +%s 2>/dev/null)
            test -n "$verified_epoch"; or continue

            set -l age (math "$now - $verified_epoch")

            if test $age -gt $threshold_seconds
                set -l rel (string replace "$docs/" "" "$file")
                set -l age_days (math -s0 "$age / 86400")
                echo "⚠ Stale verification ($age_days days): $rel"
                set stale_count (math $stale_count + 1)
                set warnings (math $warnings + 1)
            end
        end

        if test $stale_count -eq 0; and test $quiet -eq 0
            echo "✓ No pages older than $threshold_days days"
        end
    end

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------

    if test $quiet -eq 0
        echo
        echo "── Summary ──"
    end

    command rm -rf "$temp_root"

    if test $warnings -eq 0
        echo "✓ Bible audit clean"
        return 0
    end

    echo "⚠ Bible audit found $warnings warning(s)"
    echo
    echo "Useful follow-up:"
    echo "  bible-audit --metadata"
    echo "  bible-audit --sources"
    echo "  config-index"
    echo "  git status --short"
    return 1
end
