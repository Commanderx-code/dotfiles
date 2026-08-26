# Install Config Bible Batch 3

This archive contains documentation only.

From the dotfiles repository:

```fish
cd ~/dotfiles
tar -xzf ~/Downloads/config-bible-batch3-docs.tar.gz
```

Use the archive's actual path if needed.

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
config-index grub
config-index plymouth
config-index sddm
config-index kde
config-index konsole
config-index fastfetch
config-index starship
config-index topgrade
```
