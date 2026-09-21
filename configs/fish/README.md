# Fish configuration

Home Manager owns `~/.config/fish/config.fish` and initializes Fish, Fzf,
Starship, and Zoxide. Edit `home-manager/modules/fish.nix` or the relevant
program module instead of editing the generated file. Do not add separate
Starship or Zoxide startup loaders.

## Startup files

| File in `conf.d/` | Purpose |
| --- | --- |
| `aliases.fish` | Personal shortcuts and interactive abbreviations |
| `exports.fish` | Environment, executable paths, Homebrew, Go, workstation settings |
| `eza.fish` | Listing shortcuts and colors |
| `fzf.fish` | Search and preview defaults |
| `theme.fish` | Fish syntax and pager colors |
| `fastfetch.fish` | Terminal welcome |
| `done.fish` | Long-running command notifications (upstream plugin) |
| `ssh-agent.fish` | SSH agent socket and interactive key loading |
| `spotatui-autostart.fish` | Companion to the `spotatui-ghostty` launcher |

Portable functions marked with a Myfish source comment are generated imports.
Edit them in Myfish; CI checks their recorded hashes. See [shared Fish updates](../../FISH-SYNC.md)
for automation, explicit workstation overrides, and the local updater.

Keep one function per file in `functions/` so Fish can load commands on demand.
The `rgi`, `fdi`, and `cdi` commands live there instead of in startup aliases.
`fcd` picks immediate visible subdirectories; `cdi` includes hidden and nested
ones. Both use `__commander_pick_directory`, which preserves paths containing
spaces or newlines. `fish_user_key_bindings` only declares bindings; the
`**` Tab implementation lives in `__fzf_starstar_tab`.

`upgrade` uses Paru for official repositories and AUR when available, otherwise
Pacman, then updates Flatpak. It stops after a failed step. `lazyg` uses `gcom`
then pushes only after staging and committing succeed. Internal temporary-file
cleanup uses `command rm` so it cannot invoke the interactive Trash alias.

## Removed legacy configuration

The old `commander-restore` alias targeted a missing MyFish restore script.
It has been removed rather than reassigned to a different recovery operation.
Use the documented `restore-system` and `restore-apps` tools for their respective
workstation recovery tasks.

The Broot eager loader, unused icon variables and old preview helper, inactive
Rustup loader, Fish keybinding migration shim, and Fastfetch forwarding wrapper
are no longer needed. Cargo's executable path remains in `exports.fish`; a future
Rustup installation needing additional environment setup should add it there.
Go settings also live there, without writing universal variables at startup.
The theme values are preserved in `theme.fish`.

On the workstation, old `*.hm-before-cleanup` files and unmanaged duplicate
Starship, Zoxide, and Toolbox definitions were archived during cleanup.
Keep backups outside the active Fish directory. Leave `fish_variables` under
Fish's control; it is persistent shell state, not a spare startup file.

Validate changes from the repository root with
`nix develop ./home-manager --command ./scripts/check --build`, then stage new
source files before applying with `hm-rebuild` or `hms`. Open a new terminal
following cleanup so old in-memory functions and aliases disappear.

Config Bible functions and its launcher are installed by that repository's own
installer. They are no longer part of this source tree or Home Manager module
list. General workstation settings and backups remain owned by dotfiles.
