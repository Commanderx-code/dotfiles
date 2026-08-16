function full-upgrade --description "Full upgrade (pacman + paru + flatpak + topgrade)"
    echo " Updating system..."

    # Official repos
    sudo pacman -Syu

    # AUR
    echo "📦 Updating AUR (paru)..."
    paru -Syu

    # Flatpak
    if command -q flatpak
        echo "📦 Updating Flatpaks..."
        flatpak update -y
    end

    # Everything else (always)
    if command -q topgrade
        echo " Running Topgrade..."
        topgrade
    else
        echo "ℹ️ topgrade not installed (install: sudo pacman -S topgrade)"
    end

    echo "✅ Full upgrade complete"
end
