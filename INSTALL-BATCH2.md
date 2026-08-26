# Install Config Bible Batch 2

This archive contains documentation only. It does not alter the live backup/recovery scripts.

From `~/dotfiles`:

```fish
cd ~/dotfiles
tar -xzf ~/Downloads/config-bible-batch2-docs.tar.gz
```

Use the archive's actual location if it is not in `~/Downloads`.

Review:

```fish
git status --short
```

Stage:

```fish
git add docs
```

Test:

```fish
config-index backup
config-index restic
config-index restore
config-index hm-rebuild
config-index "what command"
```

Because the docs use the existing canonical singular directories (`backup`, `recovery`, `system`, etc.), they should merge cleanly with the normalized Batch 1 layout.
