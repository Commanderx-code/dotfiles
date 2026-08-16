# This function starts broot and executes the command it produces, if any.
# Needed because commands like `cd` must run in the current shell.

function br --wraps=broot
    set -l cmd_file (mktemp)

    if broot --outcmd $cmd_file $argv
        source $cmd_file
        rm -f $cmd_file
    else
        set -l code $status
        rm -f $cmd_file
        return $code
    end
end
