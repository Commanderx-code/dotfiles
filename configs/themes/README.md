# Palettes

One palette colours the whole workstation. Each file here is a palette;
`home-manager/rice.json` names the one in use (Eldritch by default), and
`home-manager/modules/theme.nix` turns it into every app's colours on
`hm-rebuild`.

```fish
rice                    # the current palette and the others
rice show nord          # colour swatches in the terminal
rice catppuccin-mocha   # switch: rebuild, then the login screen (asks for sudo)
rice nord --no-sddm     # switch, leaving the login screen as it is
```

`rice NAME` writes `rice.json` and Zed's theme, runs `hm-rebuild`, applies
Plasma's colour scheme in a Plasma session, and sets the SilentSDDM preset.
If the rebuild fails, the previous palette stays. Commit the changed files
(`home-manager/rice.json`, `configs/zed/settings.json`, `sddm/metadata.desktop`)
to keep the choice; they are listed when it finishes.

| Palette | Neovim | SDDM preset | Zed | bat / delta |
| --- | --- | --- | --- | --- |
| `eldritch` | eldritch | eldritch-cthulhu | Eldritch | ansi |
| `catppuccin-mocha` | catppuccin-mocha | catppuccin-mocha | Catppuccin Mocha | Catppuccin Mocha |
| `tokyonight-storm` | tokyonight-storm | (unchanged) | Tokyo Night Storm | ansi |
| `nord` | nord | nord | Nord | Nord |
| `gruvbox` | gruvbox-baby | gruvbox | Gruvbox Dark | gruvbox-dark |

`ansi` means bat and delta highlight with the terminal's own sixteen colours,
which are the palette's.

## What follows the palette

| App | How |
| --- | --- |
| Ghostty | `~/.config/ghostty/themes/commander` and `topbar.css`; the config needs `theme = commander` |
| Konsole | The `Commander` colour scheme, used by the Garuda profile |
| Starship | The prompt's named colours (the layout is shared from Myfish) |
| Zellij | The `commander` theme and the zjstatus bar |
| Neovim | `lua/config/rice.lua` sets LazyVim's colorscheme |
| Zed | `theme.dark` in its settings, set by `rice` |
| Plasma | The `Commander<Name>` colour scheme, through plasma-manager |
| SDDM | The SilentSDDM preset named in `apps.sddm`, set by `rice` |
| fzf, bat | `fish/conf.d/rice.fish` (generated) adds `--color` and `BAT_THEME` |
| delta | Git's pager, with the palette's diff colours |
| eza | `~/.config/eza/theme.yml` |
| lazygit | `~/.config/lazygit/theme.yml`, layered over its own `config.yml` |
| btop | `~/.config/btop/themes/commander.theme`; its `color_theme` line is set on rebuild |

Fish's syntax colours and Fastfetch use the terminal's ANSI colours, so they
follow without any changes of their own.

## Notes

- **Ghostty.** The live `~/.config/ghostty/config` is a writable copy, so it
  keeps whatever theme it had. Change its theme line to `theme = commander`
  once (and keep `gtk-custom-css = ~/.config/ghostty/topbar.css`); `rice`
  reminds you while it differs.
- **Plasma.** plasma-manager writes only the colour scheme and the
  fixed-width font (JetBrainsMono Nerd Font Mono, 10 pt). Panels, shortcuts,
  window decorations and the widget style keep what System Settings has. With
  a Kvantum widget style, Kvantum paints most widgets itself, so the colour
  scheme shows mainly in window titles, Plasma panels and non-Kvantum apps.
- **eza** uses its theme unless `LS_COLORS` is set; an `LS_COLORS` takes
  precedence over `theme.yml`.
- **First switch.** Home Manager stops, without changing anything, if a file it
  now manages already exists unmanaged (for example a hand-made
  `~/.config/eza/theme.yml`). Move it aside, or run
  `home-manager switch -b backup --flake …`, then rebuild.

## Adding a palette

Copy a file here to `<name>.json` (lowercase letters, digits and dashes) and
change its values; every colour is `#rrggbb`.

- `colors`: the fifteen roles the apps use, from `base` (background) and
  `mantle` (darker bars) to `text`, plus the accents.
- `terminal`: the sixteen ANSI colours, cursor and selection.
- `diff`: delta's background for added and removed lines.
- `apps`: the Neovim colorscheme (its plugin must be in
  `configs/nvim/lua/plugins/colorscheme.lua`), the SDDM preset in
  `sddm/configs/` or `null`, the bat theme (`bat --list-themes`, or `ansi`),
  and Zed's theme with the extension that provides it (`null` for a built-in).

Stage the new file before switching to it: the flake only sees files Git
knows about. `./scripts/check` validates every palette.
