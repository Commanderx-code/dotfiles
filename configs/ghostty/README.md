# Ghostty

The [starting preset](config) uses Catppuccin Mocha, JetBrainsMono Nerd
Font at 13 pt, 94% opacity, balanced padding, and compact Linux tabs.
The configured opening dimensions are 150 columns by 36 rows
(`window-width = 150`, `window-height = 36`). Check the usable grid with
`stty size`; integrated tabs and display scaling can affect it in this GTK build.
Ghostty supplies an integrated tab/title bar with client-side window controls.
The tab bar is always enabled, including with one tab, and is not hidden when
maximized. This also avoids relying on KDE's titlebar, which this desktop hides
for maximized windows.
It was validated with Ghostty 1.3.1 on Garuda KDE/Wayland.

The live `~/.config/ghostty/config` is a **writable copy**, so SpookiUI
can edit it. Home Manager owns [spotatui.conf](spotatui.conf) and
[topbar.css](topbar.css), not the main config.
Changes in SpookiUI do not update this repository automatically. To keep a setup
you like, copy the live config back here and review the diff before committing.
Shader files created by SpookiUI also need to be saved separately if used.
SpookiUI 1.14.0 discovers the legacy `config` filename, so this setup uses that
Ghostty-supported name. The previously empty `config.ghostty` is backed up
outside the config directory during installation to avoid conflicting files.

## Tweaking

Run `spookiui` inside Ghostty. Select a setting with Enter; `/` searches,
`a` toggles live editing, `R` reverts the session, and `q` quits.
Use `p` to save/load profiles, or `t` to explore optional animated backgrounds.
No animated background is enabled in this preset.

Run `spookiui doctor` to check the config, or `ghostty +validate-config` for
Ghostty's own validation. SpookiUI backs up configurations when it edits them.

Blur is requested by the preset, but KDE must enable the desktop Blur effect
in System Settings. Ghostty's blur intensity is controlled by KDE on Wayland.
Without that effect, the window still has subtle transparency.
Set `background-opacity = 1` for an opaque background.

The live config loads `gtk-custom-css = ~/.config/ghostty/topbar.css` to give
only the tab/title bar an opaque TokyoNight Storm background. The terminal's
90% opacity and blur are unchanged. This stylesheet is loaded by Ghostty only;
it does not change KDE or other GTK applications. Remove that config line to
restore the transparent top bar.

Reload with **Ctrl+Shift+R** or **Ctrl+Shift+,**. Open a new window for titlebar
changes that do not apply to an existing window.

| Shortcut | Action |
| --- | --- |
| Ctrl+. / Ctrl+keypad-period (KDE global) | Open a new Ghostty window from any application |
| Ctrl+Shift+T | New tab |
| Ctrl+PageUp / PageDown | Previous / next tab |
| Ctrl+Shift+O / E | Split right / down |
| Ctrl+Alt+arrow | Move between splits |
| Ctrl+Shift+Z | Zoom / unzoom split |
| Ctrl+Shift+= | Equalize splits |
| Ctrl+Shift+F | Search scrollback |
| Ctrl+, | Open config |
| Ctrl+plus / minus / 0 | Increase / decrease / reset font size |

The Ctrl+. launcher is stored by KDE in `~/.config/kglobalshortcutsrc` under
`[services][com.mitchellh.ghostty.desktop]` on `new-window`, not in
Ghostty's keybind settings. It uses the explicit New Window action rather than
the general application launcher (`_launch`). Both `Ctrl+.` and `Ctrl+Num+.`
are assigned: a focused key-capture test identified the physical shortcut on
this keyboard as the keypad variant, which KDE treats as a different shortcut.
Change it through System Settings → Keyboard → Shortcuts → Ghostty.

## Tools and provenance

[SpookiUI](https://github.com/mattj85/SpookiUI) is the selected editor: it
discovers options from the installed Ghostty, validates edits, and supports
Linux live reload. Initial installation uses v1.14.0, source revision
`a6e9c21473894e356b682bb22e7c7c3ccb46c402`, installed as
`~/.local/bin/spookiui`. `spookiui update` is its explicit update command.

[ghostty-config-cli](https://github.com/ajr-khll/ghostty-config-cli) is an
alternative Node-based appearance editor; it is not needed alongside SpookiUI.
[xkcoding's config](https://github.com/xkcoding/ghostty-config) provided ideas
for spacing and transparency; its macOS fonts and keybindings are not used.
[gtab](https://github.com/Franvy/gtab) uses macOS AppleScript and does not support
this Linux setup.

Ghostty itself remains distribution-managed. Existing Fish and Starship
configuration is reused.

## Fish integration

### Optional Zellij sessions

Zellij is installed by `home-manager/modules/zellij.nix` (imported by the terminal
module) and runs on demand,
not automatically when a terminal opens. Its generated configuration lives at
`~/.config/zellij/config.kdl`; change its settings in the Nix module, then run
`hms` to apply them. It uses Fish and the Tokyo Night Storm theme.

```sh
zellij                 # start a session
zellij --session work  # start a named session
zellij list-sessions   # list existing sessions
zellij attach work     # return to a running named session
```

Zellij starts in **locked mode**, meaning keys go to Fish and your tools instead
of Zellij; it is not a password lock. **Ctrl+G** unlocks Zellij's controls (shown
in its status bar), and **Ctrl+G** locks them again. While unlocked, **Ctrl+O**,
then **d**, detaches while leaving the session running. Fish's Ctrl+T/Ctrl+P fzf
bindings keep working while locked. Ghostty's own tab/split/global shortcuts
remain separate and unchanged.

### Zellij add-ons and project workflow

The active dotfiles setup pins [zjstatus 0.24.0](https://github.com/dj95/zjstatus),
[Harpoon 0.3.0](https://github.com/Nacho114/harpoon), and
[Zesh 0.3.0](https://github.com/roberte777/zesh). Downloads are SHA-256 checked
against upstream release metadata/checksums. Zesh uses the official Linux x86-64
binary with Nix runtime patching; this package definition is not portable to
macOS or ARM. The portable Myfish and Toolbox installers still provide the base
Zellij preset, not this workstation-specific add-on bundle.

| Command / key | Action |
| --- | --- |
| `zellij` | One Fish pane with the blue/purple/teal Powerline-style bar |
| `zdev` | Editor, Fish and Git workspace in the current directory; adds a tab if already inside Zellij |
| `zwork` | fzf picker combining Zesh's zoxide directories and sessions |
| `zwork /path/to/repo` | Open or switch to that project's session |
| Ctrl+G, then Alt+Y | Open Harpoon from locked mode |
| Harpoon: `a` / `A` | Bookmark the current pane / all panes |
| Harpoon: arrows, Enter, `d`, Esc | Navigate, jump, remove a bookmark, dismiss |
| Ctrl+G, then Ctrl+O, then `w` | Built-in session manager from locked mode |

`zwork` resolves selected Git subdirectories to their repository root. Outside
Zellij it uses Zesh; inside it uses Zellij's native session switch to avoid
nested sessions. Projects with identical directory basenames share the same
default session name; use explicitly named sessions if you have that case.
No new global/Fish hotkeys or automatic shell startup are installed.

The Git pane starts suspended: focus it and press Enter when ready to run
Lazygit. `zdev` is best in a wide window; use `zellij` for a small terminal.
Fastfetch's large welcome is suppressed in multiplexer panes, but remains in
ordinary Ghostty/Konsole windows; `fastfetch` still works manually.

Both plugins request Zellij state access/control and command execution. Harpoon
uses commands for bookmark persistence. First-run permissions were approved
through Zellij for this workstation; new users/plugin versions must approve
their own prompts. If a new install has a blank status bar, open its pinned
WASM in a floating pane (`zellij plugin --floating -- file:/path/to/zjstatus.wasm`),
switch to locked mode so `y` reaches the prompt, approve, then close that setup
session and start a new one. Do not copy permission caches between machines.

Layouts and pinned downloads live in `home-manager/modules/zellij.nix`.
Edit there and run `hms`; new layouts apply to new sessions/tabs. To restore the
built-in interface temporarily, run `zellij --new-session-with-layout default`.
The custom layouts do not define automatic swap-layout presets.

The current Nixpkgs pin installs Zellij 0.44.3. Kitty-protocol images (including
the current Ghostty fzf preview helper) are not supported inside this version;
[Kitty graphics support arrived in Zellij 0.45.0](https://zellij.dev/news/nested-sessions-kitty-graphics-new-ui/).
Use an ordinary Ghostty tab for those previews. No package pin was upgraded.

### Shared shell configuration

Ghostty starts the user's Fish shell and `shell-integration = detect` enables
Ghostty's built-in Fish integration. Home Manager loads the same aliases,
abbreviations, Starship prompt, zoxide, completions, and fzf bindings used in
other terminals. No separate Ghostty copy of the Fish configuration is needed.
The welcome message and Fastfetch startup run in both Ghostty and Konsole.

Fastfetch uses the original `~/.config/fastfetch/config.jsonc` unchanged: colored
boxed sections, the 24-column Arch logo on the left, and the full information
and color palette. The adaptive formatter is no longer used or installed.
Use a wide window (roughly 135 columns or more) for the fixed-width boxes;
they do not fit the 100-column startup window cleanly.

The welcome prints once. There is no resize signal handler: repeatedly drawing
a fetch taller than the window pushes duplicate pages into scrollback and can
interfere with Starship's multi-line prompt. Widen the window before running
`fastfetch` again; old output does not re-layout its boxes. Open a new tab to
load the restored default without touching existing scrollback. All Fastfetch
arguments pass through unchanged to the native CLI.

Fish shortcuts: Ctrl+T inserts a selected file path, Ctrl+P opens a selected
file in Neovim, Ctrl+F searches file contents, Ctrl+H searches command history,
and Alt+C selects a directory. Ghostty's own shortcuts use separate bindings.
Ctrl+Shift+PageUp / PageDown navigate between shell prompts.

The image preview helper selects Kitty graphics in Ghostty and Sixel in
Konsole. Fish syntax colors use the terminal palette; Starship has its own
explicit colors, so changing Ghostty's theme does not recolor the entire prompt.

Some helpers are intentionally specific: `kssh` invokes Kitty's SSH kitten.
`clickpaste` uses `wl-paste` and `dotool` on KDE Wayland, with `xclip` and
`xdotool` as an X11 fallback. Run it, then click the target within three seconds;
`clickpaste --delay 5` gives more time. `clickpaste --check` checks dependencies
without reading or typing clipboard contents. Newlines and tabs become Enter
and Tab keypresses. Typing follows the keyboard layout (US by default; override
with `DOTOOL_XKB_LAYOUT` / `DOTOOL_XKB_VARIANT`); use normal paste for characters
outside that layout. The current desktop grants this user `/dev/uinput` access;
a new machine must provide that permission too. No root daemon is installed.
