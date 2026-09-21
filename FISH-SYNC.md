# Shared Fish updates

Myfish is the source of truth for portable Fish functions. Edit
`Commanderx-code/Myfish/modules/fish/functions/`, commit, and push there once.
The rest of the publication pipeline is automatic:

1. Myfish validates the commit on Linux, Apple Silicon, and Intel Mac.
2. Dotfiles' **Sync shared Fish from Myfish** workflow checks at minutes 7 and 37
   each hour, on demand, and after successful dotfiles validation. GitHub may
   delay scheduled runs. Only a successful check of Myfish's current main commit
   is eligible.
3. Dotfiles imports the functions, tests and builds its combined Home Manager
   configuration, then commits and pushes the import. A concurrent human push
   stops publication rather than overwriting it.
4. The import job explicitly dispatches dotfiles validation on the new commit.
   GitHub bot-token pushes do not otherwise trigger push workflows. A later sync
   run retries a missing dispatch, but does not automatically retry failed tests.
5. Toolbox's existing source sync adopts the tested commits, builds and publishes
   its release at its next scheduled run (minutes 17 and 47).

## Ownership and workstation differences

`configs/fish/shared-source.json` records the imported Myfish revision, file
hashes, and six explicit workstation overrides. Imported functions have a source
comment at the top. CI rejects direct changes to these copies. Their fixes belong
in Myfish, so Linux and macOS are checked before dotfiles receives them.

Your startup snippets, personal functions, archive commands, direct `fdi`/`rgi`
shortcuts, expanded text-search roots, key bindings, and LAN server command remain
owned by dotfiles. The overrides are deliberate differences, not shared copies.
To make another function workstation-specific, record the reason in `overrides`
and remove its entry from `files` in the same reviewed commit before editing it.

New Myfish functions are imported automatically unless they collide with a local
function or an explicit override. Removed upstream functions are removed only
when the local copy still matches its recorded hash. Collisions, direct edits,
missing files, and symlinks stop the import for review.

This sync shares Fish function files. Myfish's portable startup scripts and
installers, and dotfiles' workstation configuration, keep their own ownership.
It does not attempt to translate arbitrary machine-specific changes into portable
code or commit unfinished local edits.

## Local updates

Home Manager installs `repo-update`:

```sh
repo-update          # fetch and report available, validated updates
repo-update --apply  # fast-forward eligible clean checkouts and rebuild Toolbox
```

The updater handles Myfish, dotfiles, and commander-toolbox beside the configured
dotfiles directory. It requires the expected origin and a branch tracking
`origin/main`, and skips dirty, detached, ahead/diverged, or in-progress Git work.
It never stashes, rebases, commits, force-pushes, or switches branches. Git also
refuses to overwrite ignored files during the fast-forward. Toolbox requires a
complete published release and is rebuilt for the existing source-checkout
launcher. Failed builds are retried on a later run; the build marker is written
only after a successful build and help smoke test.

A Codex follow-up runs this guarded command every 30 minutes on this workstation.
Local scheduled runs require the computer and Codex app to be running. GitHub's
publication pipeline runs independently of this computer. The updater's latest
results are stored in `$XDG_STATE_HOME/repo-update/state.json` (by default
`~/.local/state/repo-update/state.json`). Manage the follow-up in Codex Scheduled.

Repository updates do not activate Home Manager or run installers. Apply reviewed
workstation configuration with `hm-rebuild`; reopen Toolbox to use updated menus.
The present migration is applied once during setup.

## Checks and recovery

```sh
python3 -B scripts/sync-myfish.py --check
nix develop ./home-manager --command ./scripts/check --build
```

Use **Run workflow** on
[Sync shared Fish from Myfish](https://github.com/Commanderx-code/dotfiles/actions/workflows/sync-myfish.yml)
for an immediate import, then inspect
[dotfiles validation](https://github.com/Commanderx-code/dotfiles/actions/workflows/check.yml)
and [Toolbox source sync](https://github.com/Commanderx-code/commander-toolbox/actions/workflows/sync-sources.yml).
Failed checks keep downstream consumers on their prior tested version. GitHub
may disable scheduled workflows in inactive public repositories; re-enable them
in Actions if needed. No cross-repository secret is required.
