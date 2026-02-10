alias spico="sudo pico"
alias snano="sudo nano"
alias vim="nvim"
alias history="history | fzf"
alias fixpacman 'sudo rm /var/lib/pacman/db.lck'

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
    abbr -a ..     'cd ..'
    abbr -a ...    'cd ../..'
    abbr -a ....   'cd ../../..'
    abbr -a .....  'cd ../../../..'
    abbr -a bd     'cd -'
    abbr -a home   'cd ~'

    # command shortcuts
    abbr -a up 'update'
    abbr -a ug 'upgrade'
    abbr -a fu 'full-upgrade'
    abbr -a fud "full-upgrade-devel"
    abbr -a cl 'cleanup'
    abbr -a tg 'topgrade'
end

alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

# Clipboard paste helper (Wayland-first, X11 fallback)
function clickpaste
    sleep 3
    if command -q wl-paste
        xdotool type -- (wl-paste)
    else if command -q xclip
        xdotool type -- (xclip -o -selection clipboard)
    else
        echo "No wl-paste or xclip found"
        return 1
    end
end

alias kssh="kitty +kitten ssh"
alias sha1="openssl sha1"
alias mountedinfo="df -hT"

alias docker-clean='docker container prune -f; docker image prune -f; docker network prune -f; docker volume prune -f'
alias hug="systemctl --user restart hugo"
alias lanm="systemctl --user restart lan-mouse"

# Fuzzy search inside files (rg + fzf)
function rgi
    rg --line-number --no-heading --color=always $argv \
    | fzf --ansi --delimiter ':' \
          --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
          --preview-window 'right,60%,wrap'
end

# Fuzzy file finder -> open in nvim
function fdi
    set file (fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'bat --color=always --style=numbers --line-range :300 {}' --preview-window 'right,60%,wrap')
    test -n "$file"; and nvim "$file"
end

# Fuzzy cd
function cdi
    set dir (fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf)
    test -n "$dir"; and cd "$dir"
end
