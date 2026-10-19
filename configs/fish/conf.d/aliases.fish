# Workstation-only aliases and abbreviations. The everyday ones shared with
# Myfish (cp, mv, rm, cat, grep, find, the cd abbreviations, ...) come from
# aliases-shared.fish, which loads just before this file.
# Interactive only: scripts keep the commands' normal behaviour.
status is-interactive; or return

alias snano="sudo nano"
alias vim="nvim"

# Plain `history` opens a fuzzy picker; with arguments (search, delete,
# clear, ...) it is fish's own command.
functions -q __commander_fish_history; or functions --copy history __commander_fish_history
function history --wraps history --description 'Fuzzy-pick from history, or run a history subcommand'
    if test (count $argv) -eq 0; and isatty stdout; and command -q fzf
        builtin history | fzf --no-preview
    else
        __commander_fish_history $argv
    end
end
alias toolbox="helix-toolbox"

alias mkdir="mkdir -p"
alias ping="ping -c 10"
alias less="less -R"

# command shortcuts
abbr -a up update
abbr -a ug upgrade
abbr -a fu full-upgrade
abbr -a fud full-upgrade-devel
abbr -a cl cleanup
abbr -a tg topgrade

alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

alias sha1="openssl sha1"
