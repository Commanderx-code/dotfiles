#!/usr/bin/env fish

set -l INVENTORY "$HOME/dotfiles/system-backup/inventories"

function section
    echo
    echo "========================================"
    echo " $argv"
    echo "========================================"
    echo
end

function ask_yes_no
    set -l prompt "$argv"

    while true
        read -l -P "$prompt [y/N]: " reply

        switch (string lower -- "$reply")
            case y yes
                return 0
            case '' n no
                return 1
            case '*'
                echo "Please answer y or n."
        end
    end
end

section "Application restore"

if not test -d "$INVENTORY"
    echo "Inventory directory not found:"
    echo "  $INVENTORY"
    exit 1
end

echo "This helper can restore:"
echo
echo "  - native Pacman packages"
echo "  - foreign/AUR packages"
echo "  - Flatpak remotes"
echo "  - Flatpak applications"
echo "  - verify restored AppImages"
echo
echo "Home Manager packages should be restored separately with hm-rebuild."
echo

section "Pacman repository packages"

set -l PACMAN_NATIVE "$INVENTORY/pacman-native-explicit.txt"

if test -f "$PACMAN_NATIVE"
    echo "Saved native packages:"
    echo "  "(count (cat "$PACMAN_NATIVE"))
    echo

    echo "IMPORTANT:"
    echo "This list may contain kernels, drivers, Garuda packages and"
    echo "hardware-specific packages from the previous installation."
    echo

    if ask_yes_no "Attempt to reinstall saved native Pacman packages?"
        sudo pacman -S --needed - <"$PACMAN_NATIVE"

        if test $status -ne 0
            echo
            echo "WARNING: Some Pacman packages could not be restored."
        end
    end
else
    echo "No native Pacman inventory found."
end

section "Foreign / AUR packages"

set -l FOREIGN "$INVENTORY/pacman-foreign-explicit.txt"

if test -f "$FOREIGN"
    echo "Saved foreign packages:"
    echo "  "(count (cat "$FOREIGN"))
    echo

    if ask_yes_no "Attempt to reinstall foreign/AUR packages?"
        set -l AUR_HELPER

        if command -q paru
            set AUR_HELPER paru
        else if command -q yay
            set AUR_HELPER yay
        end

        if test -z "$AUR_HELPER"
            echo
            echo "No paru or yay installation was found."
            echo "Install an AUR helper first."
        else
            echo "Using:"
            echo "  $AUR_HELPER"
            echo

            "$AUR_HELPER" -S --needed - <"$FOREIGN"

            if test $status -ne 0
                echo
                echo "WARNING: Some foreign/AUR packages could not be restored."
            end
        end
    end
else
    echo "No foreign package inventory found."
end

section Flatpak

if not command -q flatpak
    echo "Flatpak is not installed."
else
    set -l REMOTES "$INVENTORY/flatpak-remotes.tsv"
    set -l APPS "$INVENTORY/flatpak-apps.tsv"

    if test -f "$REMOTES"
        if ask_yes_no "Restore missing Flatpak remotes?"
            while read -l line
                test -z "$line"; and continue

                set -l cols (string split \t -- "$line")

                set -l remote "$cols[1]"
                set -l url "$cols[2]"
                set -l options "$cols[3]"

                test -z "$remote"; and continue
                test -z "$url"; and continue

                if string match -q '*user*' "$options"
                    echo "User remote: $remote"

                    flatpak remote-add \
                        --user \
                        --if-not-exists \
                        "$remote" \
                        "$url"
                else
                    echo "System remote: $remote"

                    sudo flatpak remote-add \
                        --system \
                        --if-not-exists \
                        "$remote" \
                        "$url"
                end
            end <"$REMOTES"
        end
    end

    if test -f "$APPS"
        if ask_yes_no "Restore Flatpak applications?"
            while read -l line
                test -z "$line"; and continue

                set -l cols (string split \t -- "$line")

                set -l app "$cols[1]"
                set -l remote "$cols[2]"
                set -l installation "$cols[3]"

                test -z "$app"; and continue
                test -z "$remote"; and continue

                echo
                echo "Installing:"
                echo "  $app"
                echo "  from $remote"

                if string match -qi '*user*' "$installation"
                    flatpak install \
                        --user \
                        -y \
                        "$remote" \
                        "$app"
                else
                    sudo flatpak install \
                        --system \
                        -y \
                        "$remote" \
                        "$app"
                end

                if test $status -ne 0
                    echo "WARNING: Failed to restore $app"
                end
            end <"$APPS"
        end
    end
end

section AppImages

set -l APPIMAGES "$INVENTORY/appimages.txt"

if test -f "$APPIMAGES"
    echo "Saved AppImage inventory:"
    echo

    cat "$APPIMAGES"

    echo
    echo "AppImages themselves are restored through the personal Restic backup."
    echo
    echo "Checking restored files:"
    echo

    while read -l appimage
        test -z "$appimage"; and continue

        if test -f "$appimage"
            echo "OK       $appimage"
        else
            echo "MISSING  $appimage"
        end
    end <"$APPIMAGES"
else
    echo "No AppImage inventory found."
end

section "Application restore finished"

echo "Recommended checks:"
echo
echo "  pacman -Qqe"
echo "  flatpak list --app"
echo "  hm-rebuild"
echo
echo "Some packages may no longer exist or may have changed names."
echo "Review failures instead of forcing incompatible packages."
