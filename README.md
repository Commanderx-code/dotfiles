# Commander Dotfiles

Personal configuration for my **Garuda Linux / KDE Plasma** workstation, managed
with **Nix Home Manager**. Fish, Starship, Fastfetch and Neovim share one source of
truth, alongside terminal settings and backup/recovery helpers.

[![Validate dotfiles](https://github.com/Commanderx-code/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/Commanderx-code/dotfiles/actions/workflows/check.yml)

[Setup](#setup) · [Configuration](#configuration) · [Backup and recovery](#backup-and-recovery) · [Maintenance guide](STRUCTURE.md)

## Configuration

| Area | What lives here |
| :--- | :--- |
| **Theme** | One palette (Eldritch by default) for terminals, prompt, editors, CLI tools and Plasma; `rice` switches it. The SDDM login screen stays separate. See [palettes](configs/themes/README.md). |
| **Shell** | Fish functions and aliases, fzf navigation and previews, zoxide, and a Starship prompt. |
| **System overview** | Fastfetch with tree-style sections, a Garuda eagle logo, a rainbow ghost row, and alternative artwork. |
| **Editor** | Neovim / LazyVim with Snacks for the dashboard, explorer and pickers, plus language and formatting tools. |
| **Terminals** | Konsole profiles and colors, a Ghostty appearance preset, and optional Zellij workspaces. |
| **Packages and fonts** | Home Manager modules for personal tools and JetBrainsMono Nerd Font, pinned through the Nix flake lockfile. |
| **Recovery** | Restic backups, encrypted secrets archives, system snapshots, application inventories and restore helpers. |

Home Manager owns user packages and managed configuration. Pacman owns the
operating system, Plasma, terminal applications, drivers and boot components.
The [ownership map](STRUCTURE.md#ownership) describes which files are deployed
and which are reference presets or recovery material.

## Setup

This is a personal workstation configuration for `x86_64-linux` on Garuda/KDE.
[home-manager/machine.json](home-manager/machine.json) holds everything tied to
one person and machine: the username, home directory, greeting name, Git
identity, repository path, backup destination and KWallet identifiers.

### On a new machine

```sh
git clone https://github.com/Commanderx-code/dotfiles.git ~/github/projects/dotfiles
cd ~/github/projects/dotfiles
scripts/setup
```

`scripts/setup` asks for your greeting name, Git identity and backup drive, shows
its plan and waits for `APPLY`. It then rewrites `machine.json` for your account,
installs Zed, Ghostty and the other system applications with Pacman, installs Nix
when missing, and builds and activates Home Manager. Existing files that Home
Manager replaces are kept with a `.before-dotfiles` suffix.

It also installs the Rust, Go, Python and Node.js toolchains that Neovim's
language tools are built with, makes Ghostty the default terminal, and copies the
[Ghostty preset](configs/ghostty/config) when Ghostty has no config yet. An
existing Ghostty config is left alone. When the login shell is not Fish, it runs
`chsh -s /usr/bin/fish`, which takes effect at the next login.

The Fish configuration calls a few system tools that Home Manager does not
provide, and the script installs those too: `pacman-contrib` and `paru` for the
update commands, `pkgfile` for command suggestions (with its first package list),
`ksshaskpass`, `libnotify`, `7zip`, `unrar` and `poppler`.

It also offers a set of everyday apps, which you can decline: Brave Origin,
LibreOffice, GitHub CLI, bottom, yt-dlp, System Monitor and Stacer, plus Proton
Pass, Proton Mail, RustDesk and Mission Center from Flathub.

With an external drive mounted it also installs Restic, stores a repository
password in KDE Wallet and creates the repository. Without one, run it again once
the drive is attached. `scripts/setup --dry-run` asks the same questions and only
prints what would change. Fork the repository first if you plan to commit your
own `machine.json`.

### By hand

With Nix and Home Manager already available, edit `machine.json` and run:

```sh
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
| `rice` / `rice <palette>` | List the palettes, or switch the whole workstation to one. |
| `pkg-owner <command>` | Inspect whether a command comes from Pacman, Nix or another location. |
| `pkg-install <package>` | Help choose between Home Manager and system package management. |
| `zellij` | Start an optional terminal session. |
| `commander-toolbox` / `toolbox` | Open [Commander Toolbox](https://github.com/Commanderx-code/commander-toolbox), fetching its newest release first. |
| `zapfast` | Native WhatsApp client, built from its upstream flake and run through nixGL. |
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
configs/          Fish, Fastfetch, Starship, Neovim, terminal configuration and palettes
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
