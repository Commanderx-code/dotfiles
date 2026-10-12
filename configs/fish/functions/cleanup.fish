function cleanup --description "Clean caches and remove unused packages (CachyOS/Arch)"
    echo "🧹 Cleaning system..."
    set -l failed 0

    # --- Pacman orphans ---
    if command -q pacman
        set -l orphans (pacman -Qtdq 2>/dev/null)
        if test -n "$orphans"
            echo "🗑 Removing orphan packages..."
            sudo pacman -Rns $orphans; or set failed 1
        end
    end

    # --- Pacman cache (requires pacman-contrib for paccache) ---
    if command -q paccache
        echo "🧺 Cleaning pacman cache..."
        # keep last 3 versions (safe default)
        sudo paccache -rk3; or set failed 1
    else
        echo "ℹ️ Install pacman-contrib for cache cleanup: sudo pacman -S pacman-contrib"
    end

    # --- Flatpak unused ---
    if command -q flatpak
        echo "📦 Removing unused Flatpaks..."
        flatpak uninstall --unused -y; or set failed 1
    end

    # --- Journal logs (keep last 7 days) ---
    if command -q journalctl
        sudo journalctl --vacuum-time=7d; or set failed 1
    end

    if test $failed -ne 0
        echo "Cleanup finished with errors." >&2
        return 1
    end
    echo "✅ Cleanup complete"
end
