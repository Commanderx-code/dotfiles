---
title: Full Disaster Recovery
category: Recovery
managed_by: Manual procedure + Home Manager
source: ~/dotfiles/RECOVERY.md
runtime:
tags: disaster recovery reinstall restic luks gpg grub
status: active
criticality: critical
last_verified: 2026-08-26
---

# Full Disaster Recovery

## Goal

Rebuild the workstation after a failed system disk or clean reinstall while avoiding unsafe reuse of old disk identifiers or generated boot files.

## Recovery Order

```text
1. Fresh Garuda installation
2. Restore ~/dotfiles
3. Restore Nix + Home Manager
4. Run restore-system
5. Unlock and mount Linux-Backup
6. Recover Restic credential if KWallet is unavailable
7. Restore personal data to a staging directory
8. Restore SSH + KDE Wallet encrypted secrets
9. Restore/review applications and services
10. Regenerate/verify boot configuration
11. Verify firewall, systemd, Home Manager, Restic
12. Reboot and verify multiple successful boots
```

## 1 — Fresh Installation

Create the normal user:

```text
commander
```

Expected home:

```text
/home/commander
```

Let the new installation create its own:

- partitions
- filesystems
- EFI entries
- initial GRUB configuration

Do not preserve an old generated `grub.cfg` or old UUID assumptions.

## 2 — Restore Dotfiles

```fish
git clone YOUR_REPOSITORY ~/dotfiles
cd ~/dotfiles
git status
```

## 3 — Restore Home Manager

Build before switching:

```fish
home-manager build --flake ~/dotfiles/home-manager#commander
```

Then:

```fish
home-manager switch --flake ~/dotfiles/home-manager#commander
```

## 4 — Restore Saved System Configuration

```fish
restore-system
```

Current configuration is first preserved under:

```text
~/.local/state/system-restore-pre/
```

## 5 — Unlock Linux-Backup

Expected mount:

```text
/run/media/commander/Linux-Backup
```

Verify:

```fish
mountpoint /run/media/commander/Linux-Backup
```

Expected repository:

```text
/run/media/commander/Linux-Backup/restic
```

## 6 — Recover Restic Without KDE Wallet

Find the newest GPG credential:

```fish
set -l RECOVERY_FILE (
    command /usr/bin/ls --color=never -1t \
        /run/media/$USER/Linux-Backup/secrets/restic-password-*.gpg \
    | command head -n 1
)
```

Load temporarily:

```fish
set -l RECOVERED_PASSWORD (
    gpg --quiet --decrypt "$RECOVERY_FILE"
)
```

Test:

```fish
printf '%s\n' "$RECOVERED_PASSWORD" | restic \
    --repo "/run/media/$USER/Linux-Backup/restic" \
    --password-file /dev/stdin \
    snapshots
```

After use:

```fish
set -e RECOVERED_PASSWORD
```

🛑 Do not leave the Restic password in a plaintext recovery file.

## 7 — Stage Personal Restore First

```fish
mkdir -p ~/restic-restore-test
```

Then restore into the staging directory:

```fish
printf '%s\n' "$RECOVERED_PASSWORD" | restic \
    --repo "/run/media/$USER/Linux-Backup/restic" \
    --password-file /dev/stdin \
    restore latest \
    --target ~/restic-restore-test
```

Review the files before copying anything into the live home directory.

## 8 — Restore Secrets

Encrypted source:

```text
/run/media/commander/Linux-Backup/secrets
```

Restore into a temporary directory first.

SSH permissions after restoration should remain restrictive:

```fish
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
```

KDE Wallet expected runtime path:

```text
~/.local/share/kwalletd/
```

## 9 — Restore Applications

```fish
restore-apps
```

Review old kernels, drivers, hardware-specific packages, renamed packages, and removed packages instead of forcing all inventory entries.

## 10 — Boot

For Garuda initramfs rebuilding, prefer the current supported dracut workflow, such as:

```fish
sudo dracut-rebuild
```

Generate GRUB fresh from the current machine:

```fish
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

when that is the appropriate command for the installed environment.

## 11 — Verification

```fish
systemctl --failed
systemctl --user --failed
home-manager generations
sudo ufw status verbose
```

Restic:

```fish
restic \
    --repo "/run/media/$USER/Linux-Backup/restic" \
    --password-command "kwallet-query -f Restic -r Crucial-X6 kdewallet" \
    check
```

Automation:

```fish
systemctl --user status backup-on-mount.path
systemctl --user list-timers \
    restic-maintenance.timer \
    restic-deep-check.timer
```

## Never

- commit private SSH keys
- commit decrypted KDE Wallet data
- commit plaintext Restic credentials
- blindly copy an old generated `grub.cfg`
- wipe the previous working disk before verifying the replacement
- assume a backup works without testing restore access

## Always

- keep the LUKS passphrase independently available
- keep the GPG recovery passphrase independently available
- verify Restic access before destructive work
- keep at least one offline backup
- verify several successful boots before erasing the old system disk
