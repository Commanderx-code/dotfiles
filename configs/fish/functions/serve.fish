function serve
    set -l port 8000
    if test (count $argv) -ge 1
        set port $argv[1]
    end

    # -I (isolated mode) keeps the served directory off Python's import path, so
    # a file in it named like a standard-library module is served, never run.
    if command -q python3
        python3 -I -m http.server $port
    else
        python -I -m http.server $port
    end
end
