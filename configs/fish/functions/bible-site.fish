function bible-site --description "Build or serve the Config Bible web site"

    if not set -q CONFIG_BIBLE_HOME
        set -gx CONFIG_BIBLE_HOME "$HOME/github/projects/config-bible"
    end

    set -l site "$CONFIG_BIBLE_HOME/site"
    set -l venv "$site/.venv"
    set -l mkdocs "$venv/bin/mkdocs"
    set -l action "$argv[1]"
    test -n "$action"; or set action serve

    switch "$action"
        case install
            cd "$site"; or return 1
            python -m venv "$venv"; or return 1
            "$venv/bin/pip" install --upgrade pip
            "$venv/bin/pip" install -r requirements.txt
        case serve
            test -x "$mkdocs"; or begin; echo "Run: bible-site install"; return 1; end
            cd "$site"; or return 1
            "$mkdocs" serve -f mkdocs.yml
        case build
            test -x "$mkdocs"; or begin; echo "Run: bible-site install"; return 1; end
            cd "$site"; or return 1
            "$mkdocs" build -f mkdocs.yml --clean
        case help --help -h
            echo "bible-site install | serve | build"
        case '*'
            echo "Unknown action: $action"
            return 1
    end
end
