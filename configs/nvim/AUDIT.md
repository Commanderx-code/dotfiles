# Neovim audit and Snacks migration

Snacks now provides the dashboard, file explorer, and picker. lazy.nvim and
LazyVim still manage plugins, languages, formatting, and the rest of the editor.
Extras are registered in lazyvim.json so LazyVim orders their integrations.
Alpha, Neo-tree, and fzf-lua specs and lock entries have been removed.

Preserved: Revan artwork, Eldritch theme and theme choices, startup statistics,
“Ready to code!”, dashboard menu actions, hidden dashboard bars, autosave,
formatting limits, language extras, commenting and diagnostics shortcuts.

## Shortcuts and explorer behavior

- Ctrl-N toggles the explorer; `-` focuses it without closing it.
- Leader-e / Leader-fe opens the project-root explorer; uppercase E uses cwd.
- The left sidebar opens once on the first named file and follows the current
  file. Dotfiles and ignored files remain visible. Its background follows Normal.
- Explorer `h`/`l`, `O`, `Y`, and `P` close/open folders, open externally,
  copy the selected path, and preview files respectively.
- Leader-ff/fg/fb/fh/fr keep files/text/buffers/help/recent actions.
- Leader-fw/th/nt/dn now use Snacks for grep, themes, notes, and daily journals.
  The original notes/journal directories are retained.
- Ctrl-J/K moves through picker results in both normal and insert mode.
- Leader-ge/be now opens Git-status/buffer pickers (not Neo-tree sidebar sources).
- Git symbols A/M/X/=>/?/[/]/S/Y are retained. Snacks uses one status icon;
  staged S takes precedence, and there is no separate unstaged [] marker.

Validation: plugin-free regression checks cover syntax, autosave, large-file
formatting limits, dashboard bar restoration, and explorer auto-open/focus/toggle.
An isolated installed-plugin UI test also checked rendered dashboard text,
actual file results, picker navigation options, explorer settings, and removal
of the old plugin specs. Language-server/package installation and Treesitter
were disabled only in that test harness. No plugin versions were upgraded.

## Editing improvements

Nix and Markdown extras are enabled. Home Manager provides nil, nixfmt, statix,
marksman, markdownlint-cli2, markdown-toc, and prettier. Markdown rendering and
browser-preview plugins are pinned by Nix; their runtime specs live in the
Home Manager-generated nix-dependencies.lua file.

Spelling, visual wrapping, and a 140-column text width apply to Markdown, text,
and commit-message buffers. Code defaults to no wrapping/spelling and no
text-width-driven line breaks (language formatters still apply their own style).
Autosave waits 750 ms after normal-mode edits or leaving Insert mode, cancels
while typing, and reports only failures. Unsaved changes still use Neovim's
normal quit protection while a save is pending.

Shortcut changes: leader-qw quits a window; leader-bd deletes a buffer;
leader-cd shows line diagnostics; leader-nn opens notification history.
Leader-f/q/x/n are available as prefixes without single-key actions competing
with longer shortcuts. Terminal Ctrl-h/j/k/l navigation and the system file
opener are fixed. Unconfigured Cody shortcuts are removed.
Markdown: leader-cp toggles browser preview; leader-um toggles in-buffer rendering.
