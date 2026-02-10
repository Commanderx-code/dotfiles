function mkcd
    if test (count $argv) -lt 1
        echo "Usage: mkcd <dir>"
        return 1
    end
    mkdir -p -- $argv[1]
    cd -- $argv[1]
end
