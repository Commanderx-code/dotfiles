#!/usr/bin/env fish

set -l DOTFILES "$HOME/dotfiles"
set -l BACKUP "$DOTFILES/system-backup"

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
    "$BACKUP/plasma/share"

echo "==> SDDM"

if test -f /etc/sddm.conf
    sudo cp -a /etc/sddm.conf "$BACKUP/sddm/"
end

if test -d /etc/sddm.conf.d
    sudo rm -rf "$BACKUP/sddm/sddm.conf.d"
    sudo cp -a /etc/sddm.conf.d "$BACKUP/sddm/"
end

if test -d /usr/share/sddm/themes/silent
    sudo rm -rf "$BACKUP/sddm/silent"
    sudo cp -a /usr/share/sddm/themes/silent "$BACKUP/sddm/"
end

echo "==> GRUB"

if test -f /etc/default/grub
    sudo cp -a /etc/default/grub "$BACKUP/grub/grub"
end

if test -d /usr/share/grub/themes/cachyos
    sudo rm -rf "$BACKUP/grub/cachyos"
    sudo cp -a /usr/share/grub/themes/cachyos "$BACKUP/grub/"
end

echo "==> Plymouth"

if test -f /etc/plymouth/plymouthd.conf
    sudo cp -a /etc/plymouth/plymouthd.conf "$BACKUP/plymouth/"
end

if test -d /usr/share/plymouth/themes/arch-slider-and-glow
    sudo rm -rf "$BACKUP/plymouth/arch-slider-and-glow"
    sudo cp -a \
        /usr/share/plymouth/themes/arch-slider-and-glow \
        "$BACKUP/plymouth/"
end

echo "==> UFW"

if test -d /etc/ufw
    sudo rm -rf "$BACKUP/firewall/ufw"
    sudo cp -a /etc/ufw "$BACKUP/firewall/"
end

echo "==> Pacman configuration"

if test -f /etc/pacman.conf
    sudo cp -a /etc/pacman.conf "$BACKUP/pacman/"
end

for f in \
    /etc/pacman.d/mirrorlist \
    /etc/pacman.d/chaotic-mirrorlist

    if test -f "$f"
        sudo cp -a "$f" "$BACKUP/pacman/"
    end
end

# Convert files copied with sudo back to our ownership.
sudo chown -R "$USER":"$USER" \
    "$BACKUP/sddm" \
    "$BACKUP/grub" \
    "$BACKUP/plymouth" \
    "$BACKUP/firewall" \
    "$BACKUP/pacman"

echo "==> Plasma configuration"

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
            "$BACKUP/plasma/config/"
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
        rm -rf "$BACKUP/plasma/share/$d"
        cp -a "$HOME/.local/share/$d" \
            "$BACKUP/plasma/share/"
    end
end

echo "==> Package inventories"

pacman -Qqe 2>/dev/null \
    | sort >"$BACKUP/inventories/pacman-explicit.txt"

pacman -Qqm 2>/dev/null \
    | sort >"$BACKUP/inventories/aur-foreign.txt"

flatpak list \
    --app \
    --columns=application 2>/dev/null \
    | sort >"$BACKUP/inventories/flatpaks.txt"

systemctl list-unit-files \
    --state=enabled \
    --no-legend 2>/dev/null >"$BACKUP/inventories/enabled-system-services.txt"

systemctl --user list-unit-files \
    --state=enabled \
    --no-legend 2>/dev/null >"$BACKUP/inventories/enabled-user-services.txt"

echo
echo "==> Backup sizes"

du -sh "$BACKUP"/* 2>/dev/null

echo
echo "==> Git changes"

git -C "$DOTFILES" status --short

echo
echo "Backup complete."
echo
echo "NOT backed up:"
echo "  ~/.ssh"
echo "  ~/.gnupg"
echo "  KDE Wallet / keyrings"
echo "  NetworkManager credentials"
echo
echo "Those should remain in a separate encrypted backup."
