function mkcd
    if test (count $argv) -lt 1
        echo "Usage: mkcd <dir>"
        return 1
    end
    command mkdir -p -- "$argv[1]"; or return $status
    cd -- "$argv[1]"
end
