function upgrade --description "Upgrade system/AUR packages, then Flatpak"
    # Paru already upgrades official repositories along with AUR packages.
    if command -q paru
        command paru -Syu; or return $status
    else
        command sudo pacman -Syu; or return $status
    end

    if command -q flatpak
        command flatpak update -y; or return $status
    end
    return 0
end
