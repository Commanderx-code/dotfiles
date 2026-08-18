#!/usr/bin/env fish

set -l DOTFILES "$HOME/dotfiles"
set -l DEST "$DOTFILES/system-backup/inventories"

echo "========================================"
echo " Application inventory backup"
echo "========================================"
echo

mkdir -p "$DEST"

#
# Pacman
#

if command -q pacman
    echo "==> Pacman"

    # Explicit packages from official/configured repositories.
    pacman -Qqen > "$DEST/pacman-native-explicit.txt"

    # Explicit foreign packages, typically AUR/manual packages.
    pacman -Qqem > "$DEST/pacman-foreign-explicit.txt"

    # Full installed package/version list for reference.
    pacman -Q > "$DEST/pacman-all.txt"

    echo "    Native explicit:"
    echo "      "(count (cat "$DEST/pacman-native-explicit.txt"))

    echo "    Foreign explicit:"
    echo "      "(count (cat "$DEST/pacman-foreign-explicit.txt"))

    echo "    Total installed:"
    echo "      "(count (cat "$DEST/pacman-all.txt"))
else
    echo "Pacman not found."
end

echo

#
# Flatpak
#

if command -q flatpak
    echo "==> Flatpak"

    # All installed apps with origin and installation scope.
    flatpak list \
        --app \
        --columns=application,origin,installation \
        > "$DEST/flatpak-apps.tsv"

    # Runtimes are kept for reference. Apps normally reinstall required
    # runtimes automatically.
    flatpak list \
        --runtime \
        --columns=application,branch,origin,installation \
        > "$DEST/flatpak-runtimes.tsv"

    # Remote definitions.
    flatpak remotes \
        --columns=name,url,options \
        > "$DEST/flatpak-remotes.tsv"

    echo "    Applications:"
    echo "      "(count (cat "$DEST/flatpak-apps.tsv"))

    echo "    Runtimes:"
    echo "      "(count (cat "$DEST/flatpak-runtimes.tsv"))
else
    echo "Flatpak not found."
end

echo

#
# AppImages
#

echo "==> AppImages"

set -l APPIMAGE_FILE "$DEST/appimages.txt"

echo -n > "$APPIMAGE_FILE"

set -l SEARCH_DIRS \
    "$HOME/Applications" \
    "$HOME/Downloads"

for dir in $SEARCH_DIRS
    if test -d "$dir"
        command /usr/bin/find \
            "$dir" \
            -type f \
            \( -iname '*.AppImage' -o -iname '*.appimage' \) \
            -print \
            >> "$APPIMAGE_FILE"
    end
end

sort -u "$APPIMAGE_FILE" -o "$APPIMAGE_FILE"

echo "    Found:"
echo "      "(count (cat "$APPIMAGE_FILE"))

echo
echo "Inventory written to:"
echo "  $DEST"
echo
echo "Application inventory backup complete."
