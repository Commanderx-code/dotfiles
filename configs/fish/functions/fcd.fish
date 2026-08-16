function fcd
    set dir (eza -D --color=always | fzf)
    if test -n "$dir"
        cd $dir
    end
end
