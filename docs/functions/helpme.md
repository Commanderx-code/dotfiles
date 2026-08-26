---
title: helpme
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/helpme.fish
runtime: ~/.config/fish/functions/helpme.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `helpme`

## Purpose
Show Commander shortcuts (aliases, functions, tips)

## Usage
Inspect the live definition with:
```fish
type helpme
functions helpme
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/helpme.fish
cd ~/dotfiles
git add configs/fish/functions/helpme.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/helpme.fish
```

## Current Implementation
```fish
function helpme --description "Show Commander shortcuts (aliases, functions, tips)"
    set -l b (set_color --bold)
    set -l n (set_color normal)
    set -l g (set_color green)
    set -l c (set_color cyan)
    set -l y (set_color yellow)
    set -l m (set_color magenta)

    echo ""
    echo "$b$c Commander Help$n"
    echo "$y────────────────────────────────────────────────────────$n"

    echo "$b$g📦 Core$n"
    echo "  $cfastfetch$n      → system info (login shell only)"
    echo "  $cstarship$n       → prompt engine"
    echo "  $czoxide$n         → smarter cd (use: $b$czi$n)"
    echo ""

    echo "$b$g🧭 Navigation$n"
    echo "  $c..$n, $c...$n, $c....$n, $c.....$n → up directories"
    echo "  $cbd$n            → back to previous dir"
    echo "  $chome$n          → cd ~"
    echo "  $cfcd$n           → fuzzy cd (eza + fzf)"
    echo "  $cmkcd <dir>$n    → make dir + cd"
    echo ""

    echo "$b$g📂 Listing (eza)$n"
    echo "  $cls$n  → eza (icons, dirs first)"
    echo "  $cll$n  → long list"
    echo "  $cla$n  → long + all (hidden)"
    echo "  $ctree$n→ tree view"
    echo "  $clx$n  → sort by extension"
    echo "  $clk$n  → sort by size"
    echo "  $clt$n  → sort by modified"
    echo "  $cldir$n→ dirs only"
    echo "  $clf$n  → files only"
    echo "  $clg$n  → git-aware listing"
    echo ""

    echo "$b$g🧰 Utilities$n"
    echo "  $cserve [port]$n  → quick web server (default 8000)"
    echo "  $cdirsize$n       → size of current dir"
    echo "  $cpsg <name>$n    → search processes"
    echo "  $cwhatismyip$n    → internal + external IP"
    echo "  $cdocker-clean$n  → prune Docker resources"
    echo ""

    echo "$b$g🛠 Updates$n"
    echo "  $cupdate$n        → show available repo updates"
    echo "  $cupgrade$n       → pacman + paru + flatpak"
    echo "  $cfull-upgrade$n  → upgrade + topgrade (always)"
    echo "  $cfull-upgrade-devel$n → same + update -git/VCS packages"
    echo ""

    echo "$b$g🌱 Git$n"
    echo "  $cgcom \"msg\"$n   → add . && commit -m"
    echo "  $clazyg \"msg\"$n  → add . && commit && push"
    echo ""

    echo "$b$g🔎 Quick search$n"
    echo "  $ch <pat>$n       → history | grep"
    echo "  $cp <pat>$n       → ps aux | grep"
    echo ""

    echo "$y────────────────────────────────────────────────────────$n"
    echo "$mTip:$n If you want a printable list: $b$cfunctions | sort$n  and  $b$caliases$n"
    echo ""
end
```
