function serve
    set -l port 8000
    if test (count $argv) -ge 1
        set port $argv[1]
    end

    if command -q python3
        python3 -m http.server $port
    else
        python -m http.server $port
    end
end
