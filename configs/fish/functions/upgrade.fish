function upgrade --description "Upgrade packages (pacman + paru + flatpak)"
    sudo pacman -Syu
    paru -Syu

    if command -q flatpak
        flatpak update -y
    end
end
