# Commander-PC Disaster Recovery

This repository contains the configuration and recovery material needed to
rebuild the Garuda Linux workstation.

## Recovery priorities

The recovery order is:

1. Install Garuda Linux.
2. Restore the dotfiles repository.
3. Restore Home Manager configuration.
4. Restore system configuration.
5. Unlock the external backup drive.
6. Recover the Restic repository password.
7. Restore personal data.
8. Restore SSH and KDE Wallet secrets.
9. Review packages and services.
10. Reboot and verify.

---

# 1. Fresh Garuda installation

Install Garuda Linux normally.

Do not attempt to preserve an old generated `grub.cfg` or old disk UUIDs.

The new installation should create its own partitions, filesystems, EFI
entries, and initial boot configuration.

Create the normal user:

    commander

The expected home directory is:

    /home/commander

---

# 2. Restore the dotfiles repository

Install Git if required.

Clone the dotfiles repository into:

    ~/dotfiles

Enter the repository:

    cd ~/dotfiles

Review:

    git status

---

# 3. Restore Nix and Home Manager

Install Nix/Home Manager using the normal setup for this machine.

Once Home Manager is available:

    cd ~/dotfiles

    home-manager build --flake ./home-manager#commander

If the build succeeds:

    home-manager switch --flake ./home-manager#commander

This restores the declaratively managed user configuration, including
terminal configuration and helper scripts.

---

# 4. Restore saved system configuration

Run:

    restore-system

The restore script is interactive.

It can restore:

- Plasma configuration
- SDDM configuration
- Silent SDDM theme
- Plymouth configuration
- arch-slider-and-glow Plymouth theme
- GRUB source configuration
- CachyOS GRUB theme
- UFW firewall rules
- Pacman configuration

Before modifying current system configuration, it stores a pre-restore copy
under:

    ~/.local/state/system-restore-pre/

Do not delete that backup until the restored system has successfully booted.

The script intentionally does not restore an old generated grub.cfg.

Instead, it regenerates boot configuration from the current installation.

---

# 5. Unlock Linux-Backup

Connect the Crucial X6.

Unlock the LUKS container.

The expected mount point is:

    /run/media/commander/Linux-Backup

Verify:

    mountpoint /run/media/commander/Linux-Backup

The Restic repository should exist at:

    /run/media/commander/Linux-Backup/restic

Encrypted recovery files should exist at:

    /run/media/commander/Linux-Backup/secrets

---

# 6. Recover the Restic password without KWallet

The standalone encrypted Restic credential allows the repository to be
recovered even if KDE Wallet has not yet been restored.

Find the newest credential file:

    set -l RECOVERY_FILE (
        command /usr/bin/ls \
            --color=never \
            -1t \
            /run/media/$USER/Linux-Backup/secrets/restic-password-*.gpg \
        | command head -n 1
    )

Verify:

    echo "$RECOVERY_FILE"

Decrypt it:

    gpg --decrypt "$RECOVERY_FILE"

Do not leave the Restic password in a plaintext file.

To load it temporarily into Fish:

    set -l RECOVERED_PASSWORD (
        gpg --quiet --decrypt "$RECOVERY_FILE"
    )

Test access:

    printf '%s\n' "$RECOVERED_PASSWORD" | restic \
        --repo "/run/media/$USER/Linux-Backup/restic" \
        --password-file /dev/stdin \
        snapshots

After use:

    set -e RECOVERED_PASSWORD

Knowledge of the repository password is required to access the encrypted
Restic repository.

---

# 7. Restore personal files

First inspect available snapshots:

    restic \
        --repo "/run/media/$USER/Linux-Backup/restic" \
        --password-command "kwallet-query -f Restic -r Crucial-X6 kdewallet" \
        snapshots

If KWallet is not restored yet, use the recovered password instead.

Load the recovered credential:

    set -l RECOVERY_FILE (
        command /usr/bin/ls \
            --color=never \
            -1t \
            /run/media/$USER/Linux-Backup/secrets/restic-password-*.gpg \
        | command head -n 1
    )

    set -l RECOVERED_PASSWORD (
        gpg --quiet --decrypt "$RECOVERY_FILE"
    )

Inspect snapshots:

    printf '%s\n' "$RECOVERED_PASSWORD" | restic \
        --repo "/run/media/$USER/Linux-Backup/restic" \
        --password-file /dev/stdin \
        snapshots

For safety, first restore into a temporary directory instead of directly
overwriting the home directory:

    mkdir -p ~/restic-restore-test

    printf '%s\n' "$RECOVERED_PASSWORD" | restic \
        --repo "/run/media/$USER/Linux-Backup/restic" \
        --password-file /dev/stdin \
        restore latest \
        --target ~/restic-restore-test

Review the restored data carefully.

Only after verification should files be copied back into the real home
directory.

Clear the temporary password variable:

    set -e RECOVERED_PASSWORD

Restic supports restoring a snapshot into a chosen target directory, making
a staging restore preferable before copying data back into the live home.

---

# 8. Restore encrypted secrets

Encrypted secret archives are stored under:

    /run/media/commander/Linux-Backup/secrets

They contain backups of:

- ~/.ssh
- KDE Wallet data

Create a temporary restore directory:

    mkdir -p ~/secret-restore-test

Decrypt the desired archive into the temporary location.

Verify the contents before restoring them into the home directory.

SSH private keys should retain restrictive permissions.

Example:

    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_ed25519

Do not commit decrypted secrets into the dotfiles repository.

---

# 9. Restore KDE Wallet

The KDE Wallet backup contains the wallet database used by this machine.

Restore it only after verifying the decrypted archive.

Expected location:

    ~/.local/share/kwalletd/

After restoring, log out and back in if the wallet service does not pick up
the restored database immediately.

The Restic password should again be available through:

    kwallet-query -f Restic -r Crucial-X6 kdewallet

Test:

    restic \
        --repo "/run/media/$USER/Linux-Backup/restic" \
        --password-command "kwallet-query -f Restic -r Crucial-X6 kdewallet" \
        snapshots --latest 1

---

# 10. Package inventory

The saved inventories are located under:

    ~/dotfiles/system-backup/inventories/

Files include:

    pacman-explicit.txt
    aur-foreign.txt
    flatpaks.txt
    enabled-system-services.txt
    enabled-user-services.txt

Do not blindly reinstall every package.

Review the explicit package list and restore packages that are still
required.

Home Manager should be used for user-level tools that have been moved into
the declarative configuration.

System packages, drivers, kernels, desktop components, hardware support,
security packages, and system services should generally remain managed by
Garuda/pacman.

---

# 11. Boot configuration

The restore workflow restores:

    /etc/default/grub

and:

    /usr/share/grub/themes/cachyos

It does not restore an old generated:

    /boot/grub/grub.cfg

Generate a fresh configuration from the current installation.

The restore script handles this interactively.

For initramfs rebuilding on Garuda, prefer:

    sudo dracut-rebuild

If appropriate for the current installation.

---

# 12. Firewall verification

Check:

    sudo ufw status verbose

Expected policy should be reviewed before considering recovery complete.

Do not assume firewall rules are correct merely because they restored
without errors.

---

# 13. System verification

After recovery and reboot, check:

    systemctl --failed

Then:

    systemctl --user --failed

Check Home Manager:

    home-manager generations

Check Restic:

    restic \
        --repo "/run/media/$USER/Linux-Backup/restic" \
        --password-command "kwallet-query -f Restic -r Crucial-X6 kdewallet" \
        check

Check backup automation:

    systemctl --user status backup-on-mount.path

Check maintenance timers:

    systemctl --user list-timers \
        restic-maintenance.timer \
        restic-deep-check.timer

---

# 14. Backup commands after recovery

Quick personal backup:

    backup-personal

Complete manual backup:

    backup-everything

Repository maintenance:

    restic-maintenance

Deep integrity test:

    restic-deep-check

Standalone Restic credential backup:

    backup-restic-credential

---

# 15. Important recovery rules

Never:

- commit private SSH keys
- commit decrypted KDE Wallet files
- commit plaintext Restic passwords
- blindly copy an old grub.cfg to a new installation
- wipe the previous working disk before verifying the replacement system
- assume a backup is valid without testing restore access

Always:

- keep the LUKS passphrase available independently
- remember/store the GPG recovery passphrase independently
- test Restic access before destructive disk work
- keep at least one offline backup copy
- verify several successful boots before erasing an old system disk
