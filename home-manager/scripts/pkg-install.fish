#!/usr/bin/env fish

if test (count $argv) -ne 1
    echo "Usage: pkg-install <package>"
    exit 1
end

set -l PACKAGE "$argv[1]"
set -l PACKAGES_NIX "$HOME/dotfiles/home-manager/modules/packages.nix"

echo "========================================"
echo " Package installer"
echo "========================================"
echo
echo "Package:"
echo "  $PACKAGE"
echo
echo "Choose how this package should be managed:"
echo
echo "  1) Home Manager"
echo "     Personal CLI/user application"
echo "     Recreated automatically from your dotfiles"
echo
echo "  2) Pacman"
echo "     System, kernel, driver, KDE, networking,"
echo "     security, boot, filesystem or hardware package"
echo
echo "  3) Cancel"
echo

read -l -P "Choice [1/2/3]: " CHOICE

switch "$CHOICE"

    case 1
        if not test -f "$PACKAGES_NIX"
            echo "Error: packages.nix not found:"
            echo "  $PACKAGES_NIX"
            exit 1
        end

        echo
        echo "Opening:"
        echo "  $PACKAGES_NIX"
        echo
        echo "Add:"
        echo
        echo "  $PACKAGE"
        echo
        echo "inside home.packages."
        echo

        if command -q nvim
            nvim "$PACKAGES_NIX"
        else
            nano "$PACKAGES_NIX"
        end

        echo
        echo "When you're ready, run:"
        echo "  hm-rebuild"

    case 2
        echo
        echo "Installing with Pacman:"
        echo "  $PACKAGE"
        echo

        sudo pacman -S --needed "$PACKAGE"

    case 3
        echo "Cancelled."

    case '*'
        echo "Invalid selection."
        exit 1
end
