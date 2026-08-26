---
title: config-index Troubleshooting
category: Troubleshooting
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/config-index.fish
runtime: ~/.config/fish/functions/config-index.fish
tags: config-index fzf fish troubleshooting bible
status: active
criticality: normal
last_verified: 2026-08-26
---

# `config-index` Troubleshooting

## Fish Says `Unknown command: config-index`

Check source:

```fish
ls -l ~/dotfiles/configs/fish/functions/config-index.fish
```

Check Home Manager runtime link:

```fish
ls -l ~/.config/fish/functions/config-index.fish
```

If the source file is brand-new:

```fish
cd ~/dotfiles
git add configs/fish/functions/config-index.fish
hms
exec fish
```

## Syntax Check

```fish
fish -n ~/dotfiles/configs/fish/functions/config-index.fish
```

No output means the syntax check passed.

## `Ctrl-O` Says Source Is Not Available on This Host

That may be expected.

Example external sources:

```text
/DATA/compose
/var/lib/casaos/apps
```

These belong to the ZimaBoard, not the workstation.

Use:

```text
Ctrl-X
```

to copy the documented path and then access the remote host over SSH.

## No Preview

Check:

```fish
command -v bat
```

If `bat` is absent, the function falls back to `sed`.

Toggle preview with:

```text
Ctrl-/
```

## Clipboard Shortcut Only Prints the Path

Check:

```fish
command -v wl-copy
```

Install/use `wl-clipboard` if clipboard integration is desired.

## A Page Does Not Appear

Check that it:

1. lives below `~/dotfiles/docs`
2. ends in `.md`
3. is not `TEMPLATE.md`
4. is not the master `INDEX.md`
5. is not one of the old `INDEX-BATCH*.md` files

Then test:

```fish
config-index exact-title
```

## Search Results Look Wrong

Metadata is searchable.

Check the page frontmatter:

```yaml
title:
category:
status:
criticality:
tags:
source:
runtime:
```

A malformed or missing field does not prevent the document from appearing, but it may make filtering less useful.

## Recovery Shortcut Finds Nothing

`Ctrl-R` searches only:

```text
docs/recovery/
docs/backup/
docs/troubleshooting/
```

The current title is used as the starting query. Clear or edit the fzf query to browse all recovery-related pages.
