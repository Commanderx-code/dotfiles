#!/usr/bin/env fish

set -l DOTFILES "$HOME/dotfiles"

if not test -d "$DOTFILES/home-manager"
    echo "Error: $DOTFILES/home-manager does not exist."
    exit 1
end

cd "$DOTFILES"; or exit 1

echo "==> Git status"
git status --short
echo

echo "==> Home Manager build"

home-manager build --flake ./home-manager#commander

if test $status -ne 0
    echo
    echo "ERROR: Home Manager build failed."
    echo "No switch was performed."
    exit 1
end

echo
echo "==> Home Manager switch"

home-manager switch --flake ./home-manager#commander

if test $status -ne 0
    echo
    echo "ERROR: Home Manager switch failed."
    exit 1
end

echo
echo "Home Manager rebuild complete."
