# Install Config Bible Batch 4

This archive contains documentation only.

From the dotfiles repository:

```fish
cd ~/dotfiles
tar -xzf ~/Downloads/config-bible-batch4-docs.tar.gz
```

Use the actual archive path if it is stored elsewhere.

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
config-index firewall
config-index ssh
config-index kwallet
config-index apparmor
config-index networkmanager
config-index dns
config-index tailscale
config-index opnsense
```

Pages marked `planned`, `external`, or `active-external` are reference/planning pages and should not be confused with live dotfile-managed configuration.
