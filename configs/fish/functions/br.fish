# Broot emits shell commands such as cd that must run in the current shell.
function br --wraps=broot
    set -l cmd_file (command mktemp); or return $status
    command broot --outcmd "$cmd_file" $argv
    set -l result $status
    if test $result -eq 0
        source "$cmd_file"
        set result $status
    end
    command rm -f -- "$cmd_file"
    return $result
end
