#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l DOTFILES "$DOTFILES_DIR"

if not test -d "$DOTFILES/home-manager"
    echo "Error: $DOTFILES/home-manager does not exist."
    exit 1
end

cd "$DOTFILES"; or exit 1

echo "==> Git status"
git status --short
echo

echo "==> Home Manager build"

home-manager build --flake "$DOTFILES_DIR/home-manager#$HM_PROFILE"

if test $status -ne 0
    echo
    echo "ERROR: Home Manager build failed."
    echo "No switch was performed."
    exit 1
end

echo
echo "==> Home Manager switch"

home-manager switch --flake "$DOTFILES_DIR/home-manager#$HM_PROFILE"

if test $status -ne 0
    echo
    echo "ERROR: Home Manager switch failed."
    exit 1
end

echo
echo "Home Manager rebuild complete."
