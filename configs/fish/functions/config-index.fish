function config-index --description "Search the Commander configuration bible"
    dotfiles-settings; or return 1
    set -l docs_root "$CONFIG_BIBLE_HOME/docs"

    # -------------------------------------------------------------------------
    # Help / quick filters
    # -------------------------------------------------------------------------

    if contains -- --help $argv; or contains -- -h $argv
        echo "Commander Config Bible"
        echo
        echo "Usage:"
        echo "  config-index [search terms]"
        echo "  config-index --critical"
        echo "  config-index --planned"
        echo "  config-index --recovery"
        echo
        echo "fzf controls:"
        echo "  Enter    Open documentation"
        echo "  Ctrl-O   Open documented source/config"
        echo "  Ctrl-D   Change to source/document directory"
        echo "  Ctrl-Y   Copy documentation path"
        echo "  Ctrl-X   Copy documented source path"
        echo "  Ctrl-R   Search recovery / backup / troubleshooting docs"
        echo "  Ctrl-/   Toggle preview"
        echo "  Esc      Exit"
        return 0
    end

    if not test -d "$docs_root"
        echo "Config database not found:"
        echo "  $docs_root"
        return 1
    end

    if not command -q fzf
        echo "config-index requires fzf"
        return 1
    end

    set -l query (string join " " $argv)

    if contains -- --critical $argv
        set query critical
    else if contains -- --planned $argv
        set query planned
    else if contains -- --recovery $argv
        set query Recovery
    end

    set -l database (mktemp)

    # -------------------------------------------------------------------------
    # Build searchable database
    #
    # Fields:
    #  1 display icon
    #  2 title
    #  3 category
    #  4 status
    #  5 criticality
    #  6 tags
    #  7 relative doc path
    #  8 full doc path
    #  9 source path
    # 10 runtime path
    # -------------------------------------------------------------------------

    for file in (command find "$docs_root" \
        -type f \
        -name '*.md' \
        ! -name 'TEMPLATE.md' \
        ! -name 'INDEX.md' \
        ! -name 'INDEX-BATCH*.md' \
        | sort)

        set -l title (command awk -F': ' '
            $1 == "title" {
                sub(/^title:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        if test -z "$title"
            set title (command awk '
                /^# / {
                    sub(/^# /, "")
                    print
                    exit
                }
            ' "$file")
        end

        if test -z "$title"
            set title (path basename "$file" .md)
        end

        set -l category (command awk -F': ' '
            $1 == "category" {
                sub(/^category:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l status (command awk -F': ' '
            $1 == "status" {
                sub(/^status:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l criticality (command awk -F': ' '
            $1 == "criticality" {
                sub(/^criticality:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l tags (command awk -F': ' '
            $1 == "tags" {
                sub(/^tags:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l source_path (command awk -F': ' '
            $1 == "source" {
                sub(/^source:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l runtime_path (command awk -F': ' '
            $1 == "runtime" {
                sub(/^runtime:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l relative (string replace "$docs_root/" "" "$file")

        # ---------------------------------------------------------------------
        # Category icon
        # ---------------------------------------------------------------------

        set -l icon "📘"

        switch (string lower "$category")
            case index
                set icon "📚"
            case system
                set icon "⚙"
            case shell
                set icon "🐟"
            case function
                set icon "🛠"
            case commands command
                set icon "⌨"
            case editor
                set icon "✎"
            case desktop
                set icon "🖥"
            case terminal
                set icon "⌨"
            case boot
                set icon "🚀"
            case backup
                set icon "💾"
            case recovery
                set icon "🚑"
            case security
                set icon "🔐"
            case network
                set icon "🌐"
            case homelab
                set icon "🐳"
            case systemd
                set icon "⏱"
            case troubleshooting
                set icon "🧰"
            case hardware
                set icon "🖴"
            case storage
                set icon "💽"
            case "smart home" smart-home
                set icon "🏠"
        end

        # ---------------------------------------------------------------------
        # Status + criticality indicators
        # ---------------------------------------------------------------------

        set -l status_mark ""

        switch "$status"
            case active
                set status_mark "●"
            case active-external
                set status_mark "↗"
            case active-duplicate-definition
                set status_mark "⚠"
            case planned
                set status_mark "◌"
            case external
                set status_mark "↗"
            case available
                set status_mark "◇"
            case evolving
                set status_mark "◐"
            case sensitive
                set status_mark "🔒"
        end

        set -l critical_mark ""

        switch "$criticality"
            case critical
                set critical_mark "🛑"
            case important
                set critical_mark "!"
            case sensitive
                set critical_mark "🔒"
        end

        set -l display_icon "$icon$status_mark$critical_mark"

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$display_icon" \
            "$title" \
            "$category" \
            "$status" \
            "$criticality" \
            "$tags" \
            "$relative" \
            "$file" \
            "$source_path" \
            "$runtime_path" >>"$database"
    end

    # -------------------------------------------------------------------------
    # Preview command
    # -------------------------------------------------------------------------

    if command -q bat
        set preview_command 'printf "FILE: %s\n\n" {7}; bat --style=plain --color=always --line-range=:350 {8}'
    else
        set preview_command 'printf "FILE: %s\n\n" {7}; sed -n "1,350p" {8}'
    end

    # -------------------------------------------------------------------------
    # Main fzf
    # -------------------------------------------------------------------------

    set -l result (
        command cat "$database" |
        fzf \
            --delimiter='\t' \
            --with-nth=1,2,3,4,5,7 \
            --query="$query" \
            --prompt='📚 Config Bible ❯ ' \
            --pointer='▶' \
            --marker='✓' \
            --header='Enter docs │ ^O source │ ^D cd │ ^Y copy doc │ ^X copy source │ ^R recovery │ ^/ preview' \
            --preview="$preview_command" \
            --preview-window='right:60%:wrap' \
            --bind='ctrl-/:toggle-preview' \
            --expect=ctrl-o,ctrl-d,ctrl-y,ctrl-x,ctrl-r
    )

    set -l fzf_status $status

    if test $fzf_status -ne 0
        command rm -f "$database"
        return
    end

    if test (count $result) -lt 2
        command rm -f "$database"
        return
    end

    set -l action "$result[1]"
    set -l selected "$result[2]"
    set -l fields (string split \t "$selected")

    set -l title "$fields[2]"
    set -l category "$fields[3]"
    set -l doc "$fields[8]"
    set -l source_path "$fields[9]"
    set -l runtime_path "$fields[10]"

    if not test -f "$doc"
        command rm -f "$database"
        echo "Unable to locate documentation file."
        return 1
    end

    # Expand ~ in metadata paths.
    if test -n "$source_path"
        set source_path (string replace -r '^~' "$HOME" "$source_path")
    end

    if test -n "$runtime_path"
        set runtime_path (string replace -r '^~' "$HOME" "$runtime_path")
    end

    # -------------------------------------------------------------------------
    # Handle selected action
    # -------------------------------------------------------------------------

    switch "$action"

        case ctrl-o
            if test -z "$source_path"
                echo "No source path is documented for:"
                echo "  $title"
                command rm -f "$database"
                return 1
            end

            if test -e "$source_path"
                nvim "$source_path"
            else
                echo "Documented source is not available on this host:"
                echo "  $source_path"
                echo
                echo "This is normal for external entries such as ZimaBoard,"
                echo "router, OPNsense, or other remote-device documentation."
            end

        case ctrl-d
            if test -n "$source_path"; and test -e "$source_path"
                if test -d "$source_path"
                    cd "$source_path"
                else
                    cd (path dirname "$source_path")
                end
            else
                cd (path dirname "$doc")
            end

            commandline -f repaint

        case ctrl-y
            if command -q wl-copy
                printf '%s' "$doc" | wl-copy
                echo "Copied documentation path:"
                echo "  $doc"
            else
                echo "$doc"
            end

        case ctrl-x
            if test -z "$source_path"
                echo "No source path is documented for:"
                echo "  $title"
            else if command -q wl-copy
                printf '%s' "$source_path" | wl-copy
                echo "Copied source path:"
                echo "  $source_path"
            else
                echo "$source_path"
            end

        case ctrl-r
            set -l recovery_db (mktemp)

            command find "$docs_root" \
                -type f \
                -name '*.md' \
                \( \
                -path '*/recovery/*' \
                -o -path '*/backup/*' \
                -o -path '*/troubleshooting/*' \
                \) \
                | sort \
                | while read -l recovery_file

                set -l recovery_title (command awk -F': ' '
                        $1 == "title" {
                            sub(/^title:[[:space:]]*/, "")
                            print
                            exit
                        }
                    ' "$recovery_file")

                if test -z "$recovery_title"
                    set recovery_title (command awk '
                            /^# / {
                                sub(/^# /, "")
                                print
                                exit
                            }
                        ' "$recovery_file")
                end

                if test -z "$recovery_title"
                    set recovery_title (path basename "$recovery_file" .md)
                end

                set -l recovery_relative (
                        string replace "$docs_root/" "" "$recovery_file"
                    )

                printf '%s\t%s\t%s\n' \
                    "$recovery_title" \
                    "$recovery_relative" \
                    "$recovery_file" >>"$recovery_db"
            end

            set -l recovery_preview 'sed -n "1,300p" {3}'
            if command -q bat
                set recovery_preview 'bat --style=plain --color=always --line-range=:300 {3}'
            end

            set -l recovery_result (
                command cat "$recovery_db" |
                fzf \
                    --delimiter='\t' \
                    --with-nth=1,2 \
                    --query="$title" \
                    --prompt='🚑 Recovery / Troubleshooting ❯ ' \
                    --header='Enter: open │ Esc: return' \
                    --preview="$recovery_preview" \
                    --preview-window='right:60%:wrap'
            )

            command rm -f "$recovery_db"

            if test -n "$recovery_result"
                set -l recovery_fields (string split \t "$recovery_result")
                set -l recovery_doc "$recovery_fields[3]"

                if test -f "$recovery_doc"
                    nvim "$recovery_doc"
                end
            end

        case '*'
            nvim "$doc"
    end

    command rm -f "$database"
end
