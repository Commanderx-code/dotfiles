function full-upgrade-devel --description "Full upgrade including -git/VCS packages"
    echo " Updating development/VCS packages..."
    echo

    if not command -q paru
        echo "ℹ️ paru not installed"
        return 1
    end

    echo "📦 Updating AUR + -git/VCS packages..."
    paru -Syu --devel
    set -l paru_status $status

    echo

    if not command -q topgrade
        echo "ℹ️ topgrade not installed (install: sudo pacman -S topgrade)"
        return 1
    end

    echo " Running Topgrade..."
    topgrade
    set -l topgrade_status $status

    echo

    if test $paru_status -eq 0; and test $topgrade_status -eq 0
        echo "✅ Full upgrade complete (devel)"
        return 0
    else
        echo "❌ Full upgrade (devel) finished with errors"
        return 1
    end
end
