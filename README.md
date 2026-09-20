# Commander Dotfiles

Personal configuration for my **Garuda Linux / KDE Plasma** workstation, managed
with **Nix Home Manager**. Fish, Starship, Fastfetch and Neovim share one source of
truth, alongside terminal settings and backup/recovery helpers.

[![Validate dotfiles](https://github.com/Commanderx-code/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/Commanderx-code/dotfiles/actions/workflows/check.yml)

[Setup](#setup) · [Configuration](#configuration) · [Backup and recovery](#backup-and-recovery) · [Maintenance guide](STRUCTURE.md)

## Configuration

| Area | What lives here |
| :--- | :--- |
| **Shell** | Fish functions and aliases, fzf navigation and previews, zoxide, and a Starship prompt. |
| **System overview** | Fastfetch with boxed sections, an Arch logo, and alternative artwork. |
| **Editor** | Neovim / LazyVim with Snacks for the dashboard, explorer and pickers, plus language and formatting tools. |
| **Terminals** | Konsole profiles and colors, a Ghostty appearance preset, and optional Zellij workspaces. |
| **Packages and fonts** | Home Manager modules for personal tools and Nerd Fonts, pinned through the Nix flake lockfile. |
| **Recovery** | Restic backups, encrypted secrets archives, system snapshots, application inventories and restore helpers. |

Home Manager owns user packages and managed configuration. Pacman owns the
operating system, Plasma, terminal applications, drivers and boot components.
The [ownership map](STRUCTURE.md#ownership) describes which files are deployed
and which are reference presets or recovery material.

## Setup

This is a personal workstation configuration for `x86_64-linux`. It expects an
existing Garuda/KDE installation with Nix and Home Manager available. Review
[home-manager/machine.json](home-manager/machine.json) before applying it to
another account or machine: it defines the username, home directory, repository
paths, backup destination and KWallet identifiers.

```sh
git clone https://github.com/Commanderx-code/dotfiles.git ~/github/projects/dotfiles
cd ~/github/projects/dotfiles

home-manager build --flake ./home-manager#commander
home-manager switch --flake ./home-manager#commander
```

Replace `commander` in the flake target if you change the configured username.
After installation, `hm-rebuild` builds and switches using the shared machine
settings. New source files must be staged or committed before a normal Git-backed
flake build can include them.

For a guided, portable terminal setup, see [Myfish](https://github.com/Commanderx-code/Myfish).
For individual application configurations and Linux setup menus, see
[Commander Toolbox](https://github.com/Commanderx-code/commander-toolbox).

## Everyday commands

| Command | Purpose |
| :--- | :--- |
| `hm-rebuild` | Build and apply the Home Manager configuration. |
| `pkg-owner <command>` | Inspect whether a command comes from Pacman, Nix or another location. |
| `pkg-install <package>` | Help choose between Home Manager and system package management. |
| `zellij` | Start an optional terminal session. |
| `netwatch` / `tfm` / `cassette` | Network dashboard, visual file manager and Spotify player; see the [setup notes](configs/terminal-tools/README.md). |
| `zwork` / `zdev` | Pick a project session or open an editor, shell and Git workspace. |
| `backup-personal` | Back up personal files to the configured Restic repository. |
| `backup-everything` | Capture system state and inventories, back up personal files, and encrypt secrets and the Restic recovery credential. |
| `backup-health` | Review locally recorded backup status without unlocking KWallet. |
| `restore-system --dry-run` | Preview available system configuration restore sources. |
| `restore-apps --dry-run` | Preview application inventory recovery. |

Zellij starts manually in locked mode; **Ctrl+G** unlocks its controls. See the
[terminal notes](configs/ghostty/README.md) for shortcuts and project workflows,
and the [Neovim notes](configs/nvim/AUDIT.md) for editor behavior.

## Backup and recovery

Personal backups use Restic on the encrypted external drive configured in
`machine.json`. Normal runs retrieve the repository password from KDE Wallet.
Separate GPG archives protect SSH, GnuPG and KDE Wallet data, plus a standalone
Restic recovery credential.

When the backup drive mounts, a user service triggers a personal backup and
retries overdue maintenance. Weekly maintenance applies retention and pruning;
a monthly integrity check reads 10% of repository data. See the
[maintenance guide](STRUCTURE.md#backup-maintenance-and-ci) for scheduling,
health reporting and failure notifications.

**System snapshots are local backup data.** `system-backup/` is excluded from Git
and protected by Restic; a fresh clone does not contain those captures. Recover
them from your backup before using the system or application restore helpers.
The tracked `sddm/` directory has a separate role as a login-theme customization
source.

Backups do not commit or push Git changes automatically. Keep recovery passphrases
separate from the backup drive. Follow [RECOVERY.md](RECOVERY.md) for prerequisites,
credential recovery, staged restores and verification.

## Repository layout

```text
configs/          Fish, Fastfetch, Starship, Neovim and terminal configuration
home-manager/     Flake, machine settings, package modules and operational scripts
sddm/             SilentSDDM customization assets and presets
scripts/check     Repository validation entry point
tests/            Configuration and workflow checks
STRUCTURE.md      Configuration ownership, maintenance and backup behavior
RECOVERY.md       Workstation recovery procedure
```

Fonts and Lazygit come from Home Manager packages. Generated build output,
private data and local system snapshots are excluded through [.gitignore](.gitignore).

## Validation

From the repository root:

```sh
nix develop ./home-manager --command ./scripts/check --build
```

This runs syntax, formatting, workflow and documentation checks, then evaluates
and builds Home Manager without activating it. It includes unstaged source files
using a temporary copy. Omit `--build` to skip the activation-package build.
GitHub Actions runs the same build check on pushes and pull requests.

## Related repositories

| Repository | Role |
| :--- | :--- |
| [Myfish](https://github.com/Commanderx-code/Myfish) | Portable Fish, Bash and Zsh setup for Linux and macOS. |
| [Commander Toolbox](https://github.com/Commanderx-code/commander-toolbox) | Linux setup menus and individual dotfiles installers. |
| [Config Bible](https://github.com/Commanderx-code/config-bible) | Workstation handbook with web and desktop viewers. |

Config Bible owns and installs its own commands, desktop launcher, and optional
Home Manager module. Follow its repository README for installation. The full
configuration and maintenance reference for these dotfiles lives in
[STRUCTURE.md](STRUCTURE.md).

## Toolbox integration

Changes on `main` are picked up automatically after CI succeeds. Add new exported
tools to [toolbox.json](toolbox.json); see [publishing tools](TOOLBOX.md) for package
names, config paths and the update workflow.
