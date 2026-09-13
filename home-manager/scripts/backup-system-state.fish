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
    python3 "$runner" system "$DOTFILES/system-backup" (status filename)
    exit $status
end
if test (count $argv) -ne 2; or test "$argv[1]" != --capture
    echo "Usage: backup-system-state" >&2
    exit 1
end
set -l BACKUP "$argv[2]"

set -l metadata (path dirname (status filename))/snapshot-metadata.py
if not test -f "$metadata"
    set metadata "$HOME/.local/bin/snapshot-metadata"
end
python3 "$metadata" "$BACKUP/inventories" system started; or exit 1

echo "==> Backing up system state to:"
echo "    $BACKUP"
echo

mkdir -p \
    "$BACKUP/sddm" \
    "$BACKUP/grub" \
    "$BACKUP/plymouth" \
    "$BACKUP/firewall" \
    "$BACKUP/inventories" \
    "$BACKUP/pacman" \
    "$BACKUP/plasma/config" \
    "$BACKUP/plasma/share"; or exit 1

echo "==> SDDM"

if test -f /etc/sddm.conf
    sudo cp -a /etc/sddm.conf "$BACKUP/sddm/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/sddm/sddm.conf"; or exit 1
end

if test -d /etc/sddm.conf.d
    sudo rm -rf "$BACKUP/sddm/sddm.conf.d"; or exit 1
    sudo cp -a /etc/sddm.conf.d "$BACKUP/sddm/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/sddm/sddm.conf.d"; or exit 1
end

if test -d /usr/share/sddm/themes/silent
    sudo rm -rf "$BACKUP/sddm/silent"; or exit 1
    sudo cp -a /usr/share/sddm/themes/silent "$BACKUP/sddm/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/sddm/silent"; or exit 1
end

echo "==> GRUB"

if test -f /etc/default/grub
    sudo cp -a /etc/default/grub "$BACKUP/grub/grub"; or exit 1
else
    sudo rm -rf -- "$BACKUP/grub/grub"; or exit 1
end

if test -d /usr/share/grub/themes/cachyos
    sudo rm -rf "$BACKUP/grub/cachyos"; or exit 1
    sudo cp -a /usr/share/grub/themes/cachyos "$BACKUP/grub/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/grub/cachyos"; or exit 1
end

echo "==> Plymouth"

if test -f /etc/plymouth/plymouthd.conf
    sudo cp -a /etc/plymouth/plymouthd.conf "$BACKUP/plymouth/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/plymouth/plymouthd.conf"; or exit 1
end

if test -d /usr/share/plymouth/themes/arch-slider-and-glow
    sudo rm -rf "$BACKUP/plymouth/arch-slider-and-glow"; or exit 1
    sudo cp -a \
        /usr/share/plymouth/themes/arch-slider-and-glow \
        "$BACKUP/plymouth/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/plymouth/arch-slider-and-glow"; or exit 1
end

echo "==> UFW"

if test -d /etc/ufw
    sudo rm -rf "$BACKUP/firewall/ufw"; or exit 1
    sudo cp -a /etc/ufw "$BACKUP/firewall/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/firewall/ufw"; or exit 1
end

echo "==> Pacman configuration"

if test -f /etc/pacman.conf
    sudo cp -a /etc/pacman.conf "$BACKUP/pacman/"; or exit 1
else
    sudo rm -rf -- "$BACKUP/pacman/pacman.conf"; or exit 1
end

for f in \
    /etc/pacman.d/mirrorlist \
    /etc/pacman.d/chaotic-mirrorlist

    if test -f "$f"
        sudo cp -a "$f" "$BACKUP/pacman/"; or exit 1
    else
        sudo rm -f -- "$BACKUP/pacman/"(path basename "$f"); or exit 1
    end
end

# Convert files copied with sudo back to our ownership.
sudo chown -R "$USER":"$USER" \
    "$BACKUP/sddm" \
    "$BACKUP/grub" \
    "$BACKUP/plymouth" \
    "$BACKUP/firewall" \
    "$BACKUP/pacman"; or exit 1

echo "==> Plasma configuration"

rm -rf "$BACKUP/plasma/config"; or exit 1
mkdir -p "$BACKUP/plasma/config"; or exit 1

for f in \
    kdeglobals \
    kwinrc \
    kwinrulesrc \
    plasmarc \
    plasma-org.kde.plasma.desktop-appletsrc \
    kglobalshortcutsrc \
    kscreenlockerrc \
    dolphinrc \
    kiorc \
    krunnerrc

    if test -f "$HOME/.config/$f"
        cp -a "$HOME/.config/$f" \
            "$BACKUP/plasma/config/"; or exit 1
    end
end

echo "==> Plasma appearance"

# Konsole is intentionally excluded because Home Manager manages it.
# Icon themes are intentionally excluded because they add ~460 MB.

for d in \
    plasma \
    color-schemes \
    aurorae \
    wallpapers

    if test -d "$HOME/.local/share/$d"
        rm -rf "$BACKUP/plasma/share/$d"; or exit 1
        cp -a "$HOME/.local/share/$d" \
            "$BACKUP/plasma/share/"; or exit 1
    else
        rm -rf -- "$BACKUP/plasma/share/$d"; or exit 1
    end
end

echo "==> Package inventories"

pacman -Qqe 2>/dev/null \
    | sort >"$BACKUP/inventories/pacman-explicit.txt"
    if test (string join "" $pipestatus) != "00"
        exit 1
    end

pacman -Qqm 2>/dev/null \
    | sort >"$BACKUP/inventories/aur-foreign.txt"
    if test (string join "" $pipestatus) != "00"
        exit 1
    end

flatpak list \
    --app \
    --columns=application 2>/dev/null \
    | sort >"$BACKUP/inventories/flatpaks.txt"
    if test (string join "" $pipestatus) != "00"
        exit 1
    end

systemctl list-unit-files \
    --state=enabled \
    --no-legend 2>/dev/null >"$BACKUP/inventories/enabled-system-services.txt"; or exit 1

systemctl --user list-unit-files \
    --state=enabled \
    --no-legend 2>/dev/null >"$BACKUP/inventories/enabled-user-services.txt"; or exit 1

echo
echo "==> Backup sizes"

du -sh "$BACKUP"/* 2>/dev/null

echo
echo "==> Git changes"

git -C "$DOTFILES" status --short

echo
python3 "$metadata" "$BACKUP/inventories" system completed; or exit 1

echo "Backup complete."
echo
echo "NOT backed up:"
echo "  ~/.ssh"
echo "  ~/.gnupg"
echo "  KDE Wallet / keyrings"
echo "  NetworkManager credentials"
echo
echo "Those should remain in a separate encrypted backup"
