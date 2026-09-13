function bible-new --description "Create a new Config Bible page"

    dotfiles-settings; or return 1

    set -l docs "$CONFIG_BIBLE_HOME/docs"

    if contains -- --help $argv; or contains -- -h $argv
        echo "Usage: bible-new CATEGORY SLUG [TITLE] [--no-edit]"
        return 0
    end

    set -l no_edit 0
    set -l args
    for arg in $argv
        if test "$arg" = "--no-edit"
            set no_edit 1
        else
            set -a args "$arg"
        end
    end

    if test (count $args) -lt 2
        echo "Usage: bible-new CATEGORY SLUG [TITLE]"
        return 1
    end

    set -l category_input (string lower "$args[1]")
    set -l slug (string lower "$args[2]" | string replace -ar '[^a-z0-9._-]+' '-')
    set -l title ""

    if test (count $args) -ge 3
        set title (string join " " $args[3..-1])
    else
        set title (string replace -a '-' ' ' "$slug")
    end

    set -l folder "$category_input"
    set -l category "$category_input"
    set -l managed_by "Documentation"

    switch "$category_input"
        case function functions
            set folder functions; set category Function; set managed_by "Home Manager"
        case command commands
            set folder commands; set category Commands
        case shell
            set folder shell; set category Shell; set managed_by "Home Manager"
        case editor
            set folder editor; set category Editor; set managed_by "Home Manager"
        case desktop
            set folder desktop; set category Desktop
        case terminal
            set folder terminal; set category Terminal; set managed_by "Home Manager"
        case boot
            set folder boot; set category Boot; set managed_by "System"
        case backup
            set folder backup; set category Backup
        case recovery
            set folder recovery; set category Recovery
        case security
            set folder security; set category Security
        case network
            set folder network; set category Network
        case homelab
            set folder homelab; set category Homelab; set managed_by "Docker / Dockge"
        case troubleshooting
            set folder troubleshooting; set category Troubleshooting
        case hardware
            set folder hardware; set category Hardware
        case storage
            set folder storage; set category Storage
        case system
            set folder system; set category System
        case systemd
            set folder systemd; set category Systemd
    end

    set -l target "$docs/$folder/$slug.md"
    if test -e "$target"
        echo "Refusing to overwrite existing page: $target"
        return 1
    end

    mkdir -p (path dirname "$target"); or return 1
    set -l today (date +%F)

    printf '%s\n' \
        '---' \
        "title: $title" \
        "category: $category" \
        "managed_by: $managed_by" \
        'source:' \
        'runtime:' \
        "tags: $slug" \
        'status: active' \
        'criticality: normal' \
        "last_verified: $today" \
        '---' \
        '' "# $title" '' \
        '## Purpose' '' \
        'Describe what this component does and why it exists.' '' \
        '## Source of Truth' '' '```text' 'TODO' '```' '' \
        '## Usage' '' '```bash' '# TODO' '```' '' \
        '## Verification' '' '```bash' '# TODO' '```' '' \
        '## Recovery / Troubleshooting' '' 'TODO' '' \
        '## Why It Is Configured This Way' '' 'TODO' \
        > "$target"

    echo "Created: $target"
    if test $no_edit -eq 0
        nvim "$target"
    end
end
