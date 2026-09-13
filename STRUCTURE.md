# Configuration ownership and maintenance

`home-manager/machine.json` is the shared source for the username, home directory,
architecture, dotfiles and Config Bible paths, backup mount/repository, and KWallet
entry names. It contains identifiers, never the Restic password. Edit it before
building on another host. Home Manager reads it at evaluation time and installs
it as `~/.config/dotfiles/machine.json`; operational scripts read the same JSON via
`jq`. Repository scripts use the adjacent copy without requiring a prior switch.

## Ownership

| Source | Deployment or use |
| --- | --- |
| `configs/fish/` | Home Manager installs startup snippets and functions; `modules/fish.nix` owns program integration and its declared Git aliases. Eza aliases live in `conf.d/eza.fish`; `update` only checks for updates using `checkupdates`. |
| `configs/nvim/` | Home Manager deploys the entire Neovim configuration, including `.neoconf.json`. |
| `configs/starship/`, `configs/fastfetch/` | Home Manager deploys prompt and Fastfetch configuration/assets. |
| `configs/konsole/` | Home Manager installs Konsole settings, the Garuda profile, and Sweet colors. |
| `configs/ghostty/spotatui.conf` | Home Manager installs an optional Ghostty profile, not a replacement for the main Ghostty configuration. |
| `configs/topgrade/topgrade.toml` | Template rendered by Home Manager using the shared repository path/profile. Do not copy it directly. |
| `configs/scripts/fzf-preview` | Installed as `~/.local/bin/fzf-preview`. |
| `configs/fonts/` | Attribution only; `modules/fonts.nix` installs font packages from pinned Nixpkgs. |
| `home-manager/scripts/` | Installed backup, restore, and package helpers; `lib/settings.fish` supplies shared settings. |
| `home-manager/modules/backup-automation.nix` | Owns user backup services, mount watcher, and maintenance timers. `configs/systemd/user/` is an unused empty directory. |
| `sddm/` | Customization backup used by `backup-sddm` and `restore-sddm`. Restore requires an existing SilentSDDM installation. |
| `system-backup/sddm/` | Full installed SDDM snapshot used by `backup-system-state` and `restore-system`. It serves a different restore scope from `sddm/`. |
| Other `system-backup/` directories | Captured system/desktop state and inventories, restored explicitly rather than deployed through Home Manager. |

System applications (Ghostty, Konsole, Plasma, SDDM, Pacman, KWallet, and boot tools)
remain distribution-managed. Restic/GPG and filesystem utilities are recovery
prerequisites described in [RECOVERY.md](RECOVERY.md). User shell tools, fonts,
Python, and jq are declared through Home Manager.

The external Config Bible repository contains the full documentation collection.
Its location comes from `configBibleDirectory`; its app must be built separately.
Personal Restic backups include that directory. `docs.pre-bible-migration/` and
`INSTALL-BATCH*.md` are migration leftovers, not inputs to Home Manager. Keep the
old documentation until its replacement is verified, committed, and backed up.

## Validation

With Nix installed, enter the pinned validation environment:

```sh
nix develop ./home-manager
./scripts/check
./scripts/check --build
```

The check runs Fish/Bash syntax validation, ShellCheck, Nix formatting, fixture
tests, Neovim Lua syntax and behavior checks, repository Markdown link checks,
and Home Manager evaluation.
`--build` additionally builds the activation package without switching it. The
check copies only `configs/` and `home-manager/` into a temporary path flake so it
includes unstaged files without changing the Git index. Commit or stage new
source files before using the normal Git-backed Home Manager flake command.

Format Nix files with `nixfmt home-manager/*.nix home-manager/modules/*.nix`.
These checks do not run backups, perform restores, or activate a generation.

## Recovery settings and previews

Installed helpers load machine settings explicitly, including when invoked by
systemd without interactive shell startup. For a one-off recovery or fixture run,
set `DOTFILES_MACHINE_CONFIG` to another JSON file. Individual environment values
can override defaults: `DOTFILES_DIR`, `CONFIG_BIBLE_HOME`, `BACKUP_MOUNT`,
`RESTIC_REPOSITORY`, `HM_PROFILE`, `RESTIC_WALLET`, `RESTIC_WALLET_FOLDER`, and
`RESTIC_WALLET_ENTRY`. Mount and repository overrides are independent: override
both when relocating the backup repository. Rebuild Home Manager to change the
systemd mount watcher or desktop launcher.

```sh
restore-system --dry-run
restore-apps --dry-run
```

These previews list available and missing restore sources before any prompts or
writes. They do not verify that captured settings suit the destination machine.

## Snapshot provenance

Future captures write `system-metadata.json` and `applications-metadata.json`
under `system-backup/inventories/`. Each records UTC start/completion timestamps,
hostname, OS identity, kernel, architecture, dotfiles revision, and relevant tool
versions. Separate files prevent an inventory refresh from making the system
snapshot appear newer. Metadata with `status: started` indicates an interrupted
or failed capture; only a successful capture records `status: completed`.

Existing snapshots have no inferred capture date. System and application captures
share a lock, copy the current snapshot into a temporary sibling directory, and
publish only after successful commands and completion metadata. Linux's atomic
directory exchange keeps `system-backup/` available throughout publication. The
previous published tree is retained at `.system-backup.previous/`; the next
successful publication replaces that previous tree. Unmanaged snapshot assets
are preserved, while removed maintained settings are removed from new captures.

Failed captures leave the published tree unchanged and print the retained
`.system-backup-capture-*` directory for inspection. Remove failed workspaces when
no longer needed; they are excluded from Git and personal Restic captures.
The filesystem must support Linux `renameat2(RENAME_EXCHANGE)`; an unsupported
exchange fails without replacing the published snapshot. This protects against
capture/process failures, not a guarantee of durability through sudden power loss.
Metadata itself is replaced atomically.

Font binaries were removed from the current tree in favor of packages. Existing
manual font installations and Git history are preserved; this does not shrink
historical Git objects or automatically remove local font duplicates.

## Runtime checks

`bible-secrets` returns 0 for a completed scan without matches, 1 when potential
secrets are found, and 2 when a directory is missing or a search fails. It reports
filenames only. Ripgrep ignore rules still apply; this is a heuristic scan of the
searchable tree, not a guarantee that every local file is secret-free.

Neovim disables automatic formatting above 1 MiB of buffer contents and restores
the previous buffer preference when the buffer shrinks. Manual `:LazyFormat`
remains available. `ldir` lists directories and `lf` lists files.

## Backup maintenance and CI

Weekly maintenance and the monthly 10% data check record separate success dates
per repository under `$XDG_STATE_HOME/dotfiles/restic/` (default
`~/.local/state/dotfiles/restic/`). Timer and mount triggers use `--if-due`:
maintenance is due after 7 days and the data check after 30 days. An absent drive
or failed job leaves its date unchanged, so reconnecting retries overdue work.
The jobs share a lock and recheck dates after acquiring it. Directly running
`restic-maintenance` or `restic-deep-check` still forces a run.

GitHub Actions runs `nix develop ./home-manager --command ./scripts/check --build`
on pushes and pull requests, with read-only repository permissions and pinned
action revisions. It validates and builds without activating Home Manager.

## Backup coverage and health

Personal Restic captures include `~/github` (including unpushed repository work),
`~/Projects`, the configured Config Bible directory, and the existing personal
folders. `backup-secrets` separately encrypts SSH, GnuPG, and KWallet; GnuPG
sockets, lock files, and random-seed state are excluded from its archive.

`backup-health` shows locally recorded successful personal backup and maintenance
dates, snapshot metadata, backup service results, and unfinished capture folders.
It works offline and never unlocks KWallet. `backup-health --json` provides the
same information for automation; exit 1 means attention or verification is needed.
Personal backup dates start being recorded after installing this version and
completing a successful backup. An unknown date is not evidence of a failed backup.
A personal backup older than 24 hours is flagged for review.

Automatic personal backup and Restic maintenance services use systemd `OnFailure`
to display a persistent critical desktop notification. The notification includes
the failed service name and points to `backup-health`; journals remain available
when no desktop notification session is running. Manual command failures continue
to report their errors in the terminal.

Captured system files are preserved verbatim, including upstream README files.
The validator reports broken upstream links inside `system-backup/` without
failing; broken links in maintained repository documentation still fail checks.
