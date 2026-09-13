function bible-app --description "Build, develop, or launch the Config Bible desktop app"

    dotfiles-settings; or return 1

    set -l app "$CONFIG_BIBLE_HOME/app"
    set -l action "$argv[1]"
    test -n "$action"; or set action run

    switch "$action"
        case install
            cd "$app"; or return 1
            npm install
        case dev
            cd "$app"; or return 1
            npm run dev
        case build
            cd "$app"; or return 1
            npm run build
        case run
            set -l binary "$app/src-tauri/target/release/commander-config-bible"
            if test -x "$binary"
                "$binary" >/dev/null 2>&1 &
                disown
            else
                echo "Release app not built. Run: bible-app build"
                return 1
            end
        case help --help -h
            echo "bible-app install | dev | build | run"
        case '*'
            echo "Unknown action: $action"
            return 1
    end
end
