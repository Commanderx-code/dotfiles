function full-upgrade --description "Run full system and development environment upgrade"
    echo " Running full system upgrade..."
    echo

    if not command -q topgrade
        echo "ℹ️ topgrade not installed (install: sudo pacman -S topgrade)"
        return 1
    end

    echo "📦 Updating system packages..."

    echo " Running Topgrade..."
    topgrade
    set -l status_code $status

    echo

    if test $status_code -eq 0
        echo "✅ Full upgrade complete"
    else
        echo "❌ Full upgrade finished with errors"
    end

    return $status_code
end
