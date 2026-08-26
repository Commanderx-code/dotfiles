---
title: config-index
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/config-index.fish
runtime: ~/.config/fish/functions/config-index.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `config-index`

## Purpose
Search the Commander configuration bible

## Usage
Inspect the live definition with:
```fish
type config-index
functions config-index
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/config-index.fish
cd ~/dotfiles
git add configs/fish/functions/config-index.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/config-index.fish
```

## Current Implementation
```fish
function config-index --description "Search the Commander configuration bible"
    set -l docs_root "$HOME/dotfiles/docs"

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
    set -l database (mktemp)

    # -------------------------------------------------------------------------
    # Build searchable database
    # -------------------------------------------------------------------------

    for file in (command find "$docs_root" \
        -type f \
        -name '*.md' \
        ! -name 'TEMPLATE.md' \
        ! -name 'INDEX.md' \
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

        set -l tags (command awk -F': ' '
            $1 == "tags" {
                sub(/^tags:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file")

        set -l relative (string replace "$docs_root/" "" "$file")

        printf '%s\t%s\t%s\t%s\t%s\n' \
            "$title" \
            "$category" \
            "$tags" \
            "$relative" \
            "$file" \
            >> "$database"
    end

    # -------------------------------------------------------------------------
    # Preview command
    # -------------------------------------------------------------------------

    if command -q bat
        set preview_command 'bat --style=plain --color=always --line-range=:300 {5}'
    else
        set preview_command 'sed -n "1,300p" {5}'
    end

    # -------------------------------------------------------------------------
    # Launch fzf
    # -------------------------------------------------------------------------

    set -l result (
        command cat "$database" |
        fzf \
            --delimiter='\t' \
            --with-nth=1,2,3,4 \
            --query="$query" \
            --prompt='📚 Config Bible ❯ ' \
            --pointer='▶' \
            --marker='✓' \
            --header='Enter: docs │ Ctrl-O: config │ Ctrl-D: directory │ Ctrl-Y: copy path' \
            --preview="$preview_command" \
            --preview-window='right:60%:wrap' \
            --bind='ctrl-/:toggle-preview' \
            --expect=ctrl-o,ctrl-d,ctrl-y
    )

    set -l fzf_status $status

    command rm -f "$database"

    if test $fzf_status -ne 0
        return
    end

    if test (count $result) -lt 2
        return
    end

    set -l action "$result[1]"
    set -l selected "$result[2]"

    set -l fields (string split \t "$selected")

    set -l doc "$fields[5]"

    if not test -f "$doc"
        echo "Unable to locate documentation file."
        return 1
    end

    # -------------------------------------------------------------------------
    # Read source metadata
    # -------------------------------------------------------------------------

    set -l source_path (command awk -F': ' '
        $1 == "source" {
            sub(/^source:[[:space:]]*/, "")
            print
            exit
        }
    ' "$doc")

    if test -n "$source_path"
        set source_path (string replace -r '^~' "$HOME" "$source_path")
    end

    # -------------------------------------------------------------------------
    # Handle selected action
    # -------------------------------------------------------------------------

    switch "$action"

        case ctrl-o
            if test -z "$source_path"
                echo "No source path is documented for this entry."
                return 1
            end

            if not test -e "$source_path"
                echo "Documented source does not currently exist:"
                echo "  $source_path"
                return 1
            end

            nvim "$source_path"

        case ctrl-d
            if test -n "$source_path"
                if test -d "$source_path"
                    cd "$source_path"
                else if test -e "$source_path"
                    cd (path dirname "$source_path")
                else
                    cd (path dirname "$doc")
                end
            else
                cd (path dirname "$doc")
            end

            commandline -f repaint

        case ctrl-y
            if command -q wl-copy
                printf '%s' "$doc" | wl-copy
                echo "Copied:"
                echo "  $doc"
            else
                echo "$doc"
            end

        case '*'
            nvim "$doc"
    end
end
```
