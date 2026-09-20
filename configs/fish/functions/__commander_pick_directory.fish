function __commander_pick_directory --description 'Pick a directory using the supplied fd options'
    set -l directory (command fd --type d --print0 $argv 2>/dev/null | command fzf --read0 --print0 | string split0)
    test (count $directory) -eq 1; or return 0
    cd -- "$directory"
end
