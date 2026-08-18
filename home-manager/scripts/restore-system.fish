#!/usr/bin/env fish

set -l DOTFILES "$HOME/dotfiles"
set -l BACKUP "$DOTFILES/system-backup"
set -l PRE_RESTORE "$HOME/.local/state/system-restore-pre"
set -l TIMESTAMP (date "+%Y-%m-%d_%H-%M-%S")
set -l SAVE_DIR "$PRE_RESTORE/$TIMESTAMP"

function section
    echo
    echo "========================================"
    echo " $argv"
    echo "========================================"
    echo
end

function fail
    echo
    echo "ERROR: $argv"
    exit 1
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

function backup_if_exists
    set -l source "$argv[1]"
    set -l target "$argv[2]"

    if test -e "$source"
        mkdir -p (dirname "$target")
        cp -a "$source" "$target"
    end
end

section "System restore"

echo "This restores configuration from:"
echo "  $BACKUP"
echo
echo "It does NOT blindly restore:"
echo "  - old generated grub.cfg"
echo "  - old disk UUIDs"
echo "  - old EFI boot entries"
echo "  - every saved package/service automatically"
echo

if not test -d "$BACKUP"
    fail "system-backup directory not found."
end

if not test -f /etc/os-release
    fail "/etc/os-release not found."
end

source /etc/os-release

echo "Detected operating system:"
echo "  $PRETTY_NAME"
echo

if not string match -qi '*garuda*' "$PRETTY_NAME"
    echo "WARNING: This restore workflow was designed for Garuda Linux."
    echo

    if not ask_yes_no "Continue anyway?"
        exit 1
    end
end

section "Pre-restore backup"

mkdir -p "$SAVE_DIR"

echo "Saving current fresh-install configuration to:"
echo "  $SAVE_DIR"
echo

backup_if_exists /etc/default/grub "$SAVE_DIR/etc/default/grub"
backup_if_exists /etc/plymouth/plymouthd.conf "$SAVE_DIR/etc/plymouth/plymouthd.conf"
backup_if_exists /etc/sddm.conf "$SAVE_DIR/etc/sddm.conf"
backup_if_exists /etc/sddm.conf.d "$SAVE_DIR/etc/sddm.conf.d"
backup_if_exists /etc/ufw "$SAVE_DIR/etc/ufw"
backup_if_exists /etc/pacman.conf "$SAVE_DIR/etc/pacman.conf"
backup_if_exists /etc/pacman.d/mirrorlist "$SAVE_DIR/etc/pacman.d/mirrorlist"

echo "Current user Plasma configuration will also be preserved."

for file in \
    dolphinrc \
    kdeglobals \
    kglobalshortcutsrc \
    kiorc \
    krunnerrc \
    kscreenlockerrc \
    kwinrc \
    kwinrulesrc \
    plasma-org.kde.plasma.desktop-appletsrc \
    plasmarc

    backup_if_exists \
        "$HOME/.config/$file" \
        "$SAVE_DIR/home/.config/$file"
end

echo
echo "Pre-restore backup complete."

section "Home Manager"

if command -q home-manager
    echo "Home Manager found."
else
    echo "Home Manager is not currently available."
    echo
    echo "Install/restore your Nix + Home Manager environment before applying"
    echo "the declarative user configuration."
end

if command -q home-manager
    if ask_yes_no "Apply Home Manager configuration now?"
        cd "$DOTFILES"; or fail "Could not enter $DOTFILES"

        home-manager build --flake ./home-manager#commander
        or fail "Home Manager build failed."

        home-manager switch --flake ./home-manager#commander
        or fail "Home Manager switch failed."

        echo
        echo "Home Manager configuration applied."
    end
end

section "Plasma configuration"

echo "Backup contains Plasma configuration and user theme assets."
echo
echo "Restoring Plasma while Plasma is running can cause some files to be"
echo "rewritten by the current session."
echo

if ask_yes_no "Restore Plasma configuration now?"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"

    if test -d "$BACKUP/plasma/config"
        cp -a "$BACKUP/plasma/config/." "$HOME/.config/"
    end

    if test -d "$BACKUP/plasma/share"
        cp -a "$BACKUP/plasma/share/." "$HOME/.local/share/"
    end

    echo
    echo "Plasma configuration restored."
    echo "A logout/reboot is recommended after the full restore."
end

section SDDM

if ask_yes_no "Restore SDDM configuration and Silent theme?"
    if test -f "$BACKUP/sddm/sddm.conf"
        sudo cp -a "$BACKUP/sddm/sddm.conf" /etc/sddm.conf
        or fail "Failed to restore /etc/sddm.conf"
    end

    if test -d "$BACKUP/sddm/sddm.conf.d"
        sudo mkdir -p /etc/sddm.conf.d
        sudo cp -a "$BACKUP/sddm/sddm.conf.d/." /etc/sddm.conf.d/
        or fail "Failed to restore SDDM drop-in configuration."
    end

    if test -d "$BACKUP/sddm/silent"
        sudo mkdir -p /usr/share/sddm/themes/silent
        sudo cp -a "$BACKUP/sddm/silent/." /usr/share/sddm/themes/silent/
        or fail "Failed to restore Silent SDDM theme."
    end

    echo
    echo "SDDM restored."
end

section Plymouth

if ask_yes_no "Restore Plymouth configuration and theme?"
    sudo mkdir -p /etc/plymouth
    sudo mkdir -p /usr/share/plymouth/themes/arch-slider-and-glow

    if test -f "$BACKUP/plymouth/plymouthd.conf"
        sudo cp -a \
            "$BACKUP/plymouth/plymouthd.conf" \
            /etc/plymouth/plymouthd.conf
        or fail "Failed to restore Plymouth configuration."
    end

    if test -d "$BACKUP/plymouth/arch-slider-and-glow"
        sudo cp -a \
            "$BACKUP/plymouth/arch-slider-and-glow/." \
            /usr/share/plymouth/themes/arch-slider-and-glow/
        or fail "Failed to restore Plymouth theme."
    end

    echo
    echo "Plymouth files restored."
end

section "GRUB source configuration"

echo "This restores /etc/default/grub and the CachyOS theme assets."
echo
echo "It does NOT copy an old generated grub.cfg."
echo

if ask_yes_no "Restore GRUB source configuration and theme?"
    if test -f "$BACKUP/grub/grub"
        sudo mkdir -p /etc/default
        sudo cp -a "$BACKUP/grub/grub" /etc/default/grub
        or fail "Failed to restore /etc/default/grub"
    end

    if test -d "$BACKUP/grub/cachyos"
        sudo mkdir -p /usr/share/grub/themes/cachyos
        sudo cp -a \
            "$BACKUP/grub/cachyos/." \
            /usr/share/grub/themes/cachyos/
        or fail "Failed to restore GRUB theme."
    end

    echo
    echo "GRUB source configuration restored."
end

section Firewall

if ask_yes_no "Restore UFW configuration?"
    if not command -q ufw
        echo "UFW is not installed."
        echo "Install it before restoring the saved firewall rules."
    else
        if test -d "$BACKUP/firewall/ufw"
            sudo mkdir -p /etc/ufw
            sudo cp -a "$BACKUP/firewall/ufw/." /etc/ufw/
            or fail "Failed to restore UFW configuration."

            echo
            echo "UFW configuration restored."

            if ask_yes_no "Enable UFW now?"
                sudo systemctl enable --now ufw
                or echo "WARNING: Could not enable ufw.service."

                sudo ufw reload
                or echo "WARNING: UFW reload returned an error."

                sudo ufw status verbose
            end
        end
    end
end

section "Pacman configuration"

echo "The backup contains:"
echo "  pacman.conf"
echo "  mirrorlist"
echo "  chaotic-mirrorlist"
echo
echo "These can become stale, so they are not restored automatically."
echo

if ask_yes_no "Restore saved pacman.conf and mirrorlists?"
    if test -f "$BACKUP/pacman/pacman.conf"
        sudo cp -a "$BACKUP/pacman/pacman.conf" /etc/pacman.conf
        or fail "Failed to restore pacman.conf"
    end

    if test -f "$BACKUP/pacman/mirrorlist"
        sudo mkdir -p /etc/pacman.d
        sudo cp -a "$BACKUP/pacman/mirrorlist" /etc/pacman.d/mirrorlist
        or fail "Failed to restore mirrorlist"
    end

    if test -f "$BACKUP/pacman/chaotic-mirrorlist"
        sudo mkdir -p /etc/pacman.d
        sudo cp -a \
            "$BACKUP/pacman/chaotic-mirrorlist" \
            /etc/pacman.d/chaotic-mirrorlist
        or fail "Failed to restore chaotic-mirrorlist"
    end

    echo
    echo "Pacman configuration restored."
    echo "Review it before performing a full system upgrade."
end

section "Package inventories"

echo "Package inventories were intentionally NOT installed automatically."
echo
echo "Review these files:"
echo
echo "  $BACKUP/inventories/pacman-explicit.txt"
echo "  $BACKUP/inventories/aur-foreign.txt"
echo "  $BACKUP/inventories/flatpaks.txt"
echo "  $BACKUP/inventories/enabled-system-services.txt"
echo "  $BACKUP/inventories/enabled-user-services.txt"
echo

if test -f "$BACKUP/inventories/pacman-explicit.txt"
    echo "Explicit pacman packages:"
    count (cat "$BACKUP/inventories/pacman-explicit.txt")
end

if test -f "$BACKUP/inventories/aur-foreign.txt"
    echo "Foreign/AUR packages:"
    count (cat "$BACKUP/inventories/aur-foreign.txt")
end

section "Boot rebuild"

echo "Boot-related files may have changed."
echo
echo "The initramfs and GRUB configuration should be regenerated from"
echo "the CURRENT installation rather than restoring generated files."
echo

if ask_yes_no "Rebuild initramfs now?"
    if command -q dracut-rebuild
        sudo dracut-rebuild
        or fail "dracut-rebuild failed."
    else if command -q dracut
        echo "dracut-rebuild was not found."
        echo "Falling back to:"
        echo "  sudo dracut --regenerate-all --force"
        sudo dracut --regenerate-all --force
        or fail "dracut rebuild failed."
    else
        echo "No dracut rebuild command found."
        echo "Skipping initramfs rebuild."
    end
end

if ask_yes_no "Regenerate GRUB configuration now?"
    if command -q update-grub
        sudo update-grub
        or fail "update-grub failed."
    else if command -q grub-mkconfig
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        or fail "grub-mkconfig failed."
    else
        echo "Neither update-grub nor grub-mkconfig was found."
        echo "Skipping GRUB regeneration."
    end
end

section "Restore complete"

echo "System configuration restore steps are complete."
echo
echo "Pre-restore copies are stored at:"
echo "  $SAVE_DIR"
echo
echo "Still review/restore separately:"
echo "  - personal files from Restic"
echo "  - SSH keys"
echo "  - KDE Wallet"
echo "  - package inventory"
echo "  - enabled services"
echo
echo "Recommended next step:"
echo "  reboot"
echo
echo "Do not delete the pre-restore backup until the system has"
echo "successfully rebooted and you have verified everything."
