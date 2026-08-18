# Dotfiles – Garuda Linux Environment & Recovery Framework

This repository contains my personal **Garuda Linux** configuration, Home Manager setup, backup tooling, and disaster-recovery workflow.

It is designed to make my workstation reproducible while keeping system-level configuration, personal data, and secrets backed up through the appropriate tools instead of treating everything as a normal Git-tracked dotfile.

## What this repo manages

- 🐟 **Fish shell environment** – functions, `conf.d`, fzf helpers, and shell tooling
- ✨ **Terminal setup** – Starship, Fastfetch, Konsole, Ghostty, themes, and helper scripts
- 📝 **Neovim / LazyVim configuration**
- ❄️ **Home Manager** – declarative user packages and configuration
- 📦 **Application inventory** – Pacman, AUR/foreign packages, Flatpak apps/remotes, and AppImages
- 💾 **Restic personal backups** – documents, downloads, pictures, projects, applications, dotfiles, Cargo state, and more
- 🔐 **Encrypted secrets backups** – SSH and KDE Wallet data stored separately from Git
- 🔑 **Standalone Restic recovery credential** – GPG-encrypted copy for disaster recovery without depending on KWallet
- 🖥️ **System configuration snapshots** – SDDM, GRUB, Plymouth, UFW, Pacman configuration, Plasma settings, and package/service inventories
- 🔁 **Automatic backup on external-drive mount**
- 🧹 **Scheduled Restic maintenance** – retention/pruning plus repository checks
- 🩺 **Monthly deeper Restic integrity checks**
- 🛟 **Interactive restore helpers** for system configuration and installed applications

This repository is both my **dotfiles collection** and a lightweight **configuration / disaster-recovery framework** for my Garuda workstation.

---

## Repository layout

```text
dotfiles/
├── configs/
│   ├── fish/                  # Fish conf.d, functions, and shell configuration
│   ├── fastfetch/             # Fastfetch configuration/assets
│   ├── ghostty/               # Ghostty-specific configuration
│   ├── konsole/               # Konsole profile/theme/configuration
│   ├── nvim/                  # Neovim / LazyVim configuration
│   ├── scripts/               # Shared helper scripts
│   └── starship/              # Starship prompt configuration
│
├── home-manager/
│   ├── home.nix               # Main Home Manager configuration
│   ├── flake.nix              # Home Manager flake
│   ├── modules/               # Package and application-specific modules
│   └── scripts/               # Managed backup/recovery/helper commands
│
├── system-backup/
│   ├── firewall/              # UFW configuration snapshot
│   ├── grub/                  # GRUB source configuration + theme
│   ├── inventories/           # Pacman/AUR/Flatpak/AppImage/service inventories
│   ├── pacman/                # pacman.conf and mirrorlists
│   ├── plasma/                # Plasma/KDE configuration and appearance assets
│   ├── plymouth/              # Plymouth configuration + theme
│   └── sddm/                  # SDDM configuration + Silent theme
│
├── RECOVERY.md                # Full disaster-recovery procedure
├── README.md
└── .gitignore
```

---

## Home Manager

Home Manager is the primary way I manage portable user-level packages and configuration.

Apply the current configuration with:

```fish
cd ~/dotfiles
home-manager build --flake ./home-manager#commander
home-manager switch --flake ./home-manager#commander
```

A convenience helper is also installed:

```fish
hm-rebuild
```

### Package ownership helpers

Check whether a command comes from Pacman, Nix/Home Manager, or elsewhere:

```fish
pkg-owner <command>
```

For example:

```fish
pkg-owner fd
pkg-owner grub-mkconfig
```

Use the package-install helper when deciding whether a package belongs in Home Manager or Pacman:

```fish
pkg-install <package>
```

General rule:

- **Home Manager:** personal CLI/user tools that should follow my dotfiles
- **Pacman:** kernels, drivers, Plasma/KDE, boot components, networking, filesystem tools, security tooling, and other system infrastructure

---

## Backup system

### Quick personal backup

```fish
backup-personal
```

The Restic repository lives on the encrypted external backup drive at:

```text
/run/media/commander/Linux-Backup/restic
```

The external drive uses LUKS encryption, and the Restic repository password is normally retrieved from KDE Wallet.

### Full backup

```fish
backup-everything
```

A full backup currently performs:

1. System configuration snapshot
2. Application/package inventory refresh
3. Personal Restic backup
4. Encrypted SSH + KDE Wallet backup
5. Encrypted standalone Restic recovery credential backup

Git changes are intentionally **not committed or pushed automatically**.

### System configuration snapshot

```fish
backup-system-state
```

This captures important workstation configuration such as:

- SDDM configuration and Silent theme
- GRUB source configuration and theme
- Plymouth configuration and theme
- UFW configuration
- Pacman configuration/mirrorlists
- Plasma/KDE configuration and appearance assets
- Pacman/AUR/Flatpak/application inventories
- enabled system/user service inventories

### Application inventory

```fish
backup-app-inventory
```

This records:

- native explicit Pacman packages
- foreign/AUR packages
- full Pacman package/version list
- Flatpak applications
- Flatpak runtimes
- Flatpak remotes
- AppImage locations

AppImages stored under `~/Applications` are also physically included in the Restic backup.

---

## Automatic Restic backups

When the encrypted `Linux-Backup` drive is unlocked and mounted, the user systemd path unit triggers an automatic personal backup.

Check it with:

```fish
systemctl --user status backup-on-mount.path
```

View the most recent automatic run with:

```fish
journalctl --user -u backup-on-mount.service --since "10 minutes ago"
```

---

## Restic maintenance

### Weekly maintenance

```fish
restic-maintenance
```

The retention policy keeps approximately:

- 7 daily snapshots
- 5 weekly snapshots
- 12 monthly snapshots
- 3 yearly snapshots

The weekly job also prunes unused repository data and runs a standard repository check.

Check the timer with:

```fish
systemctl --user status restic-maintenance.timer
```

### Monthly deeper integrity check

```fish
restic-deep-check
```

This performs a deeper Restic check that reads a subset of the stored backup data.

Check the timer with:

```fish
systemctl --user status restic-deep-check.timer
```

---

## Encrypted secrets

Secrets are intentionally **not stored in Git**.

Encrypted backups are written to:

```text
/run/media/commander/Linux-Backup/secrets
```

The secrets workflow currently protects:

- `~/.ssh`
- KDE Wallet data
- standalone Restic recovery credential

Create the SSH/KWallet encrypted backup with:

```fish
backup-secrets "/run/media/commander/Linux-Backup/secrets"
```

Create a standalone encrypted Restic credential with:

```fish
backup-restic-credential
```

The GPG recovery passphrase and LUKS passphrase must be kept independently from the backup drive.

---

## Restore / disaster recovery

The full recovery procedure is documented in:

```text
RECOVERY.md
```

### Restore system configuration

```fish
restore-system
```

`restore-system` is interactive and intentionally cautious. It can restore the backed-up Plasma, SDDM, Plymouth, GRUB source configuration, UFW, and related configuration while avoiding unsafe assumptions such as blindly restoring an old generated `grub.cfg` or old disk UUIDs.

### Restore applications

```fish
restore-apps
```

This helper can use the saved inventories to assist with restoring:

- native Pacman packages
- AUR/foreign packages
- Flatpak remotes
- Flatpak applications
- AppImage verification

Home Manager packages are restored separately through the Home Manager configuration.

---

## Recovery philosophy

Different data is restored by different tools:

```text
Home Manager     -> portable user configuration + user packages
Git/dotfiles     -> tracked configuration and recovery scripts
system-backup    -> system/desktop configuration snapshots
Restic           -> personal files and selected development state
GPG archives     -> SSH, KDE Wallet, and recovery credentials
Package manifests-> Pacman, AUR, Flatpak, and AppImage recovery
```

This keeps secrets out of Git, avoids backing up large amounts of reproducible system data unnecessarily, and provides a clear recovery path after a reinstall or disk failure.

---

## Important rules

Never commit:

- SSH private keys
- decrypted KDE Wallet files
- plaintext Restic passwords
- NetworkManager credential files
- decrypted secret archives

Before destructive disk work:

```fish
backup-everything
```

Then verify the Restic repository:

```fish
restic \
    --repo "/run/media/$USER/Linux-Backup/restic" \
    --password-command "kwallet-query -f Restic -r Crucial-X6 kdewallet" \
    check
```

For complete reinstall and recovery steps, see **`RECOVERY.md`**.
