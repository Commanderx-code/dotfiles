# Workstation-only aliases and abbreviations. The everyday ones shared with
# Myfish (cp, mv, rm, cat, grep, find, the cd abbreviations, ...) come from
# aliases-shared.fish, which loads just before this file.
alias snano="sudo nano"
alias vim="nvim"
alias history="history | fzf"
alias fixpacman 'sudo rm /var/lib/pacman/db.lck'
alias toolbox="commander-toolbox"

alias mkdir="mkdir -p"
alias ping="ping -c 10"
alias less="less -R"
alias home="cd ~"

# command shortcuts
if status is-interactive
    abbr -a up update
    abbr -a ug upgrade
    abbr -a fu full-upgrade
    abbr -a fud full-upgrade-devel
    abbr -a cl cleanup
    abbr -a tg topgrade
end

alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

alias sha1="openssl sha1"
