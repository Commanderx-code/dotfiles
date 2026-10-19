# Publishing tools to HelixForge

`toolbox.json` is this repository's exported menu for
[HelixForge](https://github.com/Commanderx-code/Helix-Forge), which replaced
Commander Toolbox. Commit the configuration and its catalog entry together, then
push to `main`. When this repository's `check.yml` succeeds on `main`, the
**Notify HelixForge** workflow starts HelixForge's source sync, which adopts the
revision only after verifying that successful check itself. Failed or unfinished
checks leave the previous source version in place. HelixForge also checks on a
schedule, but GitHub runs that only every few hours.

HelixForge renders each exported entry as a catalog file, runs its checks,
builds the Linux x86_64 and aarch64 applications, and publishes a release with
their checksums; the `toolbox` launcher downloads the one for its processor.
Existing installations pick up the new entries the next time `helixforge` (or
`toolbox`) starts; run the entry to apply the configuration. Installing an
application locally does not export it automatically.

## Update an existing tool

Edit its tracked configuration or installer and push normally. Built-in catalog
entries keep their dedicated HelixForge installers. Myfish's shell entries run the
updated Myfish installer, including any new tools it manages.

NetWatch, TFM and Spotify Cassette use dedicated Nix handlers. Their pinned
packages live in [home-manager/terminal-tools.nix](home-manager/terminal-tools.nix),
shared by Home Manager and HelixForge; see the [setup notes](configs/terminal-tools/README.md).

## Export a new application configuration

Add a `config` entry to the `entries` array in `toolbox.json`. For example, after
adding an actual `configs/btop/btop.conf` file:

```json
{
  "id": "btop",
  "name": "Btop Monitor",
  "description": "Install Btop and the shared monitor configuration.",
  "type": "config",
  "packages": {
    "apt-get": ["btop"],
    "dnf": ["btop"],
    "pacman": ["btop"]
  },
  "files": [
    {"source": "configs/btop/btop.conf", "target": "btop/btop.conf"}
  ]
}
```

- `id`: stable lowercase identifier with letters, numbers and hyphens.
- `name`: unique menu label across HelixForge; `description` explains the install.
- `packages`: distro package names, separately for each supported package manager.
  An empty array supports configuration-only installation on that manager; omit a
  manager to reject it. Nala uses the `apt-get` entry. Packages must exist in the
  user's enabled repositories; the installer does not add repositories.
- `files`: tracked source files or directories, relative to this repository.
  Targets are relative to `$XDG_CONFIG_HOME` (normally `~/.config`). Export only the
  configuration needed by the tool. Symlinks and paths outside the repo are rejected.

HelixForge lists the new entry under Configurations > Dotfiles. Its installer
asks for `APPLY`, validates all paths, installs the declared packages, then
copies configuration with backups. HelixForge also refuses, before anything
runs, an entry whose target is a Home Manager symlink. Directory exports replace
the destination directory with a backup; use individual files to preserve
unrelated files alongside them. Multiple file copies are not a single
transaction: earlier successful copies keep their backups if a later copy fails.

The `builtin` type references an existing dedicated HelixForge handler. Keep
those entries when editing the catalog. Tools requiring custom system services,
boot changes or a special installer still need an appropriate HelixForge
handler; this catalog's generic installer manages distro packages and user
configuration only.

## Check the automation

Open [HelixForge source synchronization](https://github.com/Commanderx-code/Helix-Forge/actions/workflows/sync-sources.yml).
**Run workflow** checks immediately. The workflow log shows which source
revision was accepted or is waiting for CI. Builds appear under
[HelixForge releases](https://github.com/Commanderx-code/Helix-Forge/releases).
Starting that workflow from here needs the `HELIXFORGE_DISPATCH_TOKEN` secret:
a fine-grained token for Commanderx-code/Helix-Forge with only **Actions: Read
and write**. [HelixForge's sync guide](https://github.com/Commanderx-code/Helix-Forge/blob/main/docs/SOURCE-SYNC.md#notifications-from-the-sources)
shows how to create it. Without it, the notifier only leaves a notice and
HelixForge adopts the revision on its next push or scheduled run.

GitHub disables scheduled workflows in public repos after 60 days without repo
activity; re-enable the workflow in Actions if necessary. HelixForge watches
dotfiles and Myfish; new source repositories need an explicit integration.

Shared portable Fish functions are maintained in Myfish and imported automatically
after successful CI. See [shared Fish updates](FISH-SYNC.md) for source ownership
and automatic local checkout updates. Bot-created imports use explicitly
dispatched `check.yml` validation before HelixForge can adopt them.
