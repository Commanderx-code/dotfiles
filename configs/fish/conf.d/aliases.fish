# Personal command aliases and interactive abbreviations.
alias spico="sudo pico"
alias snano="sudo nano"
alias vim="nvim"
alias history="history | fzf"
alias fixpacman 'sudo rm /var/lib/pacman/db.lck'
alias fresh="fr"
alias toolbox="commander-toolbox"

alias web="cd /var/www/html"
alias da='date "+%Y-%m-%d %A %T %Z"'

alias cp="cp -i"
alias mv="mv -i"
alias rm="trash -v"
alias mkdir="mkdir -p"

# cat -> bat
alias cat="bat"
alias ccat="/bin/cat"

alias ping="ping -c 10"
alias cls="clear"
alias psa="ps auxf"
alias less="less -R"
alias find='fd'
alias cfind='/usr/bin/find'

# Prefer rg interactively
alias grep="rg"
alias cgrep="/usr/bin/grep"

alias home="cd ~"

# Directory jumps (interactive only)
if status is-interactive
    abbr -a .. 'cd ..'
    abbr -a ... 'cd ../..'
    abbr -a .... 'cd ../../..'
    abbr -a ..... 'cd ../../../..'
    abbr -a bd 'cd -'
    abbr -a home 'cd ~'

    # command shortcuts
    abbr -a up update
    abbr -a ug upgrade
    abbr -a fu full-upgrade
    abbr -a fud full-upgrade-devel
    abbr -a cl cleanup
    abbr -a tg topgrade
end

alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

alias kssh="kitty +kitten ssh"
alias sha1="openssl sha1"
alias mountedinfo="df -hT"

alias docker-clean='docker container prune -f; docker image prune -f; docker network prune -f; docker volume prune -f'
alias hug="systemctl --user restart hugo"
alias lanm="systemctl --user restart lan-mouse"
