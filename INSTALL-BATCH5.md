# Install Config Bible Batch 5

This archive contains documentation only.

From the workstation dotfiles repository:

```fish
cd ~/dotfiles
tar -xzf ~/Downloads/config-bible-batch5-docs.tar.gz
```

Use the actual path if the archive is elsewhere.

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
config-index zimaboard
config-index docker
config-index dockge
config-index tugtainer
config-index homepage
config-index uptime
config-index home-assistant
config-index zigbee
config-index tailscale
config-index adguard
```

Important: Batch 5 intentionally does not reproduce secret values found in `.env` or CasaOS application definitions.
