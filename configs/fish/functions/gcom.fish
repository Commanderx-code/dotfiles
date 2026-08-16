function gcom
    git add .
    if test (count $argv) -eq 0
        echo "Usage: gcom <message>"
        return 1
    end
    git commit -m (string join ' ' -- $argv)
end
