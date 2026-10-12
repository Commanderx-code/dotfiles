function extract --description 'Extract an archive into the current directory'
    if test (count $argv) -ne 1
        echo 'Usage: extract <archive-file>' >&2
        return 1
    end
    if not test -f "$argv[1]"
        echo "❌ File not found: $argv[1]" >&2
        return 1
    end

    switch $argv[1]
        case "*.tar.bz2"
            tar xvjf $argv[1]
        case "*.tar.gz"
            tar xvzf $argv[1]
        case "*.bz2"
            bunzip2 $argv[1]
        case "*.rar"
            unrar x $argv[1]
        case "*.gz"
            gunzip $argv[1]
        case "*.tar"
            tar xvf $argv[1]
        case "*.tbz2"
            tar xvjf $argv[1]
        case "*.tgz"
            tar xvzf $argv[1]
        case "*.zip"
            unzip $argv[1]
        case "*.7z"
            7z x $argv[1]
        case "*"
            echo "Unknown archive: $argv[1]" >&2
            return 1
    end
end
