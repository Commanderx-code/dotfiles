# Terminal tools

NetWatch, TFM and Cassette are installed by the workstation's Home Manager
configuration. They start manually; existing file managers and music players
remain available. All three upstream Linux x86_64 releases are pinned by version
and SHA-256 in [terminal-tools.nix](../../home-manager/terminal-tools.nix).
Update those pins and run the repository build checks before publishing changes.

| Command | Use |
| --- | --- |
| `netwatch` | Network dashboard; `netwatch doctor` checks local capabilities. |
| `netwatch --demo` | Explore the dashboard using demonstration data. |
| `tfm` | Mouse-friendly file manager; use a full Ghostty window for image previews. |
| `cassette` | Spotify player; requires Premium, a developer app and initial login. |

NetWatch runs without root for ordinary monitoring. Packet capture needs extra
privileges; installation does not grant capabilities, start a daemon or change DNS.
TFM is a beta release. Its writable settings live under `~/.config/tfm/`; image,
video and Wayland clipboard helpers are included. Cross-application drag-and-drop
is an upstream Kitty-specific feature.

## Cassette login

This package is [OreoMuncher45/cassette](https://github.com/OreoMuncher45/cassette),
not the unrelated Yandex Music application named `cassette` in Nixpkgs.
The wrapper includes librespot for local audio playback through PulseAudio or
PipeWire's PulseAudio service.

1. In your Spotify developer app, allow `http://127.0.0.1:8080/callback` as a
   Redirect URI.
2. Create `~/.config/cassette/config.yml` locally with the settings below. Replace
   the placeholder with your Client ID. No client secret is needed.
3. Run `cassette` and complete the browser login. If local playback needs a second
   login, run `cassette setup` and follow librespot's browser authorization.

```yaml
auth:
  client_id: YOUR_SPOTIFY_CLIENT_ID
  host: 127.0.0.1
  port: 8080
  redirect-endpoint: /callback
  timeout: 300
```

Keep this file private (`chmod 600 ~/.config/cassette/config.yml`). Do not copy
the live Cassette directory, tokens or cache into this repository. Home Manager
does not generate this config, keeping credentials outside Git and the Nix store.
The explicit port above overrides the v1.0.0 release's default of 8287.

## Toolbox and updates

The Dotfiles menu exports individual installers for all three tools. They require
an existing Nix installation with flakes and Linux x86_64. On another machine,
Toolbox installs the selected package into your Nix profile from its tested
dotfiles revision. It preserves an already available command; update an existing
installation with its package manager. On this workstation, use `hm-rebuild`.

Toolbox's source sync publishes the updated menu and source pin after dotfiles CI
passes. It does not install software or change Spotify credentials in the
background. New Nix profile installs need the profile's `bin` directory on PATH.

To stop including these trials on the workstation, remove the `terminal-trials.nix`
import from [terminal.nix](../../home-manager/modules/terminal.nix) and rebuild.
For a separate Toolbox installation, use `nix profile list` and
`nix profile remove <name>` to remove the chosen profile package.
