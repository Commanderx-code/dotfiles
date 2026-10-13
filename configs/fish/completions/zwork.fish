# Known projects and sessions from zesh, or any directory.
complete -c zwork -f
complete -c zwork -n '__fish_is_first_arg; and command -q zesh' -a '(command zesh list 2>/dev/null)'
complete -c zwork -n __fish_is_first_arg -a '(__fish_complete_directories)'
