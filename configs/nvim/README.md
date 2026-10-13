# Neovim

LazyVim on lazy.nvim. Snacks provides the dashboard, file explorer and picker;
LazyVim manages plugins, languages and formatting. Language extras are listed in
`lazyvim.json` so LazyVim orders their integrations.

Home Manager installs this folder read-only and provides nil, nixfmt, statix,
marksman, markdownlint-cli2, markdown-toc, prettier, the tree-sitter CLI, and the
basedpyright, ruff and Bash language servers it shares with Zed. The Markdown rendering and
browser-preview plugins are pinned by Nix; their specs are in the generated
`lua/plugins/nix-dependencies.lua`. Plugin versions are recorded in
`lazy-lock.json` in this checkout.

## Shortcuts

| Keys | Action |
| --- | --- |
| Ctrl-N | Toggle the explorer |
| `-` | Focus the explorer without closing it |
| Leader-e / Leader-fe | Explorer at the project root (uppercase E: working directory) |
| Leader-ff / fg / fb / fh / fr | Find files, text, buffers, help, recent files |
| Leader-fw | Live grep |
| Leader-th | Colorscheme picker; the choice is remembered |
| Leader-ge / be | Git status and buffer pickers |
| Leader-nn | Notification history |
| Leader-qw | Quit the window |
| Leader-qv | Save the project session |
| Leader-/ | Comment the line or selection |
| Leader-tb | Terminal in a horizontal split |
| Alt-i | Toggle a terminal in the project root |
| Leader-of | Open the working directory in the file manager |
| Leader-cp / Leader-um | Markdown browser preview / in-buffer rendering |
| Ctrl-h/j/k/l | Move between windows, also from a terminal |
| Ctrl-J / Ctrl-K in a picker | Move through results |
| J / K in visual mode | Move the selection down or up |
| jk or jj in insert mode | Escape |

In the explorer, `h`/`l` close and open folders, `O` opens with the system
application, `Y` copies the path and `P` previews. Git symbols are
A/M/X/=>/?/[/]/S/Y; a staged S takes precedence.

## Behaviour

- The explorer opens once, on the first named file, without taking the cursor, and
  follows the current file.
  Dotfiles and ignored files stay visible.
- Autosave waits 750 ms after a normal-mode edit or leaving Insert mode, cancels
  while you type and reports only failures.
- Files over 1 MB are not formatted on save; `:LazyFormat` still works.
- Markdown, text and commit messages get spelling, wrapping and a 140-column text
  width. Code gets none of the three.
- The dashboard hides the status line, tab line and command line, and restores
  them when you leave it.

`tests/check_nvim.lua` checks syntax, autosave, the large-file limit, dashboard
bar restoration and the explorer without loading plugins.
