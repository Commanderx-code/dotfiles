#!/usr/bin/env fish

# Load shared settings without relying on interactive Fish startup.
set -l settings_file (path dirname (status filename))/lib/settings.fish
if not test -f "$settings_file"
    set settings_file "$HOME/.local/share/dotfiles/settings.fish"
end
source "$settings_file"; or exit 1

set -l DOTFILES "$DOTFILES_DIR"
# Public invocation publishes a complete capture; --capture is used by the runner.
if test (count $argv) -eq 0
    set -l runner (path dirname (status filename))/snapshot-transaction.py
    if not test -f "$runner"
        set runner "$HOME/.local/bin/snapshot-transaction"
    end
    python3 "$runner" applications "$DOTFILES/system-backup" (status filename)
    exit $status
end
if test (count $argv) -ne 2; or test "$argv[1]" != --capture
    echo "Usage: backup-app-inventory" >&2
    exit 1
end
set -l DEST "$argv[2]/inventories"

set -l metadata (path dirname (status filename))/snapshot-metadata.py
if not test -f "$metadata"
    set metadata "$HOME/.local/bin/snapshot-metadata"
end
python3 "$metadata" "$DEST" applications started; or exit 1

echo "========================================"
echo " Application inventory backup"
echo "========================================"
echo

mkdir -p "$DEST"; or exit 1

#
# Pacman
#

if command -q pacman
    echo "==> Pacman"

    # Explicit packages from official/configured repositories.
    pacman -Qqen > "$DEST/pacman-native-explicit.txt"; or exit 1

    # Explicit foreign packages, typically AUR/manual packages.
    pacman -Qqem > "$DEST/pacman-foreign-explicit.txt"; or exit 1

    # Full installed package/version list for reference.
    pacman -Q > "$DEST/pacman-all.txt"; or exit 1

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
        > "$DEST/flatpak-apps.tsv"; or exit 1

    # Runtimes are kept for reference. Apps normally reinstall required
    # runtimes automatically.
    flatpak list \
        --runtime \
        --columns=application,branch,origin,installation \
        > "$DEST/flatpak-runtimes.tsv"; or exit 1

    # Remote definitions.
    flatpak remotes \
        --columns=name,url,options \
        > "$DEST/flatpak-remotes.tsv"; or exit 1

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
            >> "$APPIMAGE_FILE"; or exit 1
    end
end

sort -u "$APPIMAGE_FILE" -o "$APPIMAGE_FILE"; or exit 1

echo "    Found:"
echo "      "(count (cat "$APPIMAGE_FILE"))

echo
echo "Inventory written to:"
echo "  $DEST"
echo
python3 "$metadata" "$DEST" applications completed; or exit 1

echo "Application inventory backup complete."
