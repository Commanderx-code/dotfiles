function update --description "Show available updates (Arch)"
    if command -q checkupdates
        checkupdates
        return
    end

    echo "Tip: install pacman-contrib for checkupdates: sudo pacman -S pacman-contrib"
    return 1
end
