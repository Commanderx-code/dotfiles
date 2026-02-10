function full-upgrade-devel --description "Full upgrade including -git/VCS packages"
    echo " Updating system (including -git/VCS)..."

    # Official repos
    sudo pacman -Syu

    # AUR + VCS
    echo "📦 Updating AUR (paru --devel)..."
    paru -Syu --devel

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

    echo "✅ Full upgrade complete (devel)"
end
