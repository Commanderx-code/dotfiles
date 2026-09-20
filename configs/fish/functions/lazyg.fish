function lazyg --description 'Stage, commit, and push; stop on any failure'
    if test (count $argv) -eq 0
        echo "Usage: lazyg <message>"
        return 1
    end
    gcom $argv; or return $status
    command git push
end
