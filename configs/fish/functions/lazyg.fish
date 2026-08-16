function lazyg
    git add .
    if test (count $argv) -eq 0
        echo "Usage: lazyg <message>"
        return 1
    end
    git commit -m (string join ' ' -- $argv)
    git push
end
