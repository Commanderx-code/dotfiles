# Commander Config Bible

> Start with [START-HERE.md](START-HERE.md) or run `config-index`.

## Workstation

### System / Home Manager

- [Home Manager — Fish and Neovim](system/home-manager-fish-neovim.md)
- [Home Manager Helper Commands](system/home-manager-helpers.md)
- [Package and Application Inventories](system/package-inventories.md)
- [Topgrade](system/topgrade.md)

### Shell

- [Fish Shell](shell/fish.md)
- [fzf Integration](shell/fzf.md)
- [Starship Prompt](shell/starship.md)

### Editor

- [Neovim / LazyVim](editor/neovim.md)
- [Neovim Keymaps](editor/neovim-keymaps.md)
- [Neovim LSP](editor/neovim-lsp.md)
- [Neovim Plugins](editor/neovim-plugins.md)
- [Neovim Snippets](editor/neovim-snippets.md)

### Desktop / Terminal

- [KDE Plasma](desktop/kde-plasma.md)
- [Konsole](desktop/konsole.md)
- [Ghostty](desktop/ghostty.md)
- [Fastfetch](desktop/fastfetch.md)
- [SDDM / SilentSDDM](desktop/sddm.md)
- [SilentSDDM Revan Preset](desktop/sddm-revan-preset.md)
- [Terminal Configuration Management](terminal/terminal-management.md)

### Boot

- [GRUB](boot/grub.md)
- [Plymouth](boot/plymouth.md)

## Functions and Commands

- [Fish Function Reference](commands/fish-function-reference.md)
- [Fish Alias Reference](commands/fish-alias-reference.md)
- [What Command Should I Use?](commands/what-command-should-i-use.md)

Individual function pages live under:

```text
docs/functions/
```

Examples:

- `config-index`
- `full-upgrade`
- `full-upgrade-devel`
- `fzf_open_file`
- `fzf_rg_search`
- `backup-personal`
- `backup-everything`
- `hm-rebuild`
- `pkg-owner`
- `pkg-install`
- `restic-maintenance`
- `restic-deep-check`

## Backup and Recovery

### Backup

- [Backup System Overview](backup/overview.md)
- [System State Backup](backup/system-state.md)
- [SDDM Backup and Restore](backup/sddm.md)

### Recovery

- [Full Disaster Recovery](recovery/disaster-recovery.md)
- [restore-system](recovery/restore-system.md)
- [restore-apps](recovery/restore-apps.md)
- [ZimaBoard Container Recovery](homelab/recovery.md)

### Automation

- [Backup Automation](systemd/backup-automation.md)

## Security

- [UFW Firewall](security/firewall.md)
- [UFW Network Hardening Sysctl](security/firewall-sysctl.md)
- [AppArmor](security/apparmor.md)
- [SSH](security/ssh.md)
- [SSH Agent Startup](security/ssh-agent.md)
- [KDE Wallet](security/kwallet.md)
- [GPG Secret Backup Encryption](security/gpg.md)
- [Secrets Management](security/secrets-management.md)

## Networking

- [NetworkManager](network/networkmanager.md)
- [DNS Strategy](network/dns.md)
- [NextDNS](network/nextdns.md)
- [Technitium DNS](network/technitium.md)
- [Tailscale](network/tailscale.md)
- [ASUS / Merlin](network/asus-merlin.md)
- [OPNsense](network/opnsense.md)
- [Network Security Architecture](network/router-security.md)

## Homelab

### Core

- [ZimaBoard / ZimaOS](homelab/zimaboard.md)
- [Container Directory Layout](homelab/container-layout.md)
- [Docker](homelab/docker.md)
- [Dockge](homelab/dockge.md)
- [Tugtainer](homelab/tugtainer.md)

### Services

- [Homepage](homelab/homepage.md)
- [Uptime Kuma](homelab/uptime-kuma.md)
- [Glances](homelab/glances.md)
- [Dozzle](homelab/dozzle.md)
- [Home Assistant](homelab/home-assistant.md)
- [Zigbee2MQTT + Mosquitto](homelab/zigbee2mqtt-mosquitto.md)
- [Tailscale on ZimaBoard](homelab/tailscale-zima.md)
- [AdGuard Home](homelab/adguard-home.md)
- [Unbound](homelab/unbound.md)
- [CasaOS User Management](homelab/casaos-user-management.md)

## Troubleshooting

- [Fish Troubleshooting](troubleshooting/fish.md)
- [Neovim Troubleshooting](troubleshooting/neovim.md)
- [Backup and Recovery Review Notes](troubleshooting/batch2-review-notes.md)
- [Desktop and Boot Troubleshooting](troubleshooting/desktop-boot.md)
- [Security and Network Troubleshooting](troubleshooting/security-network.md)
- [ZimaBoard Container Troubleshooting](troubleshooting/zimaboard-containers.md)

## Status Vocabulary

Documentation pages may use:

```text
active
active-external
planned
external
available
evolving
sensitive
active-duplicate-definition
```

These describe the relationship between the Bible and the live system.

`active`
: live and managed/documented directly.

`active-external`
: live, but configuration is outside this dotfiles repository.

`planned`
: intended future deployment.

`external`
: managed on another device/service.

`available`
: usable option, but not necessarily current primary configuration.

`evolving`
: architecture is still being designed.

`sensitive`
: contains or depends on privileged/security-sensitive configuration.

`active-duplicate-definition`
: multiple management definitions exist and ownership should be verified before cleanup.
