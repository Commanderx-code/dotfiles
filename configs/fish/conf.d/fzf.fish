# -----------------------------
# FZF (Fish)
# -----------------------------

# Load fzf fish keybindings + completion

# Default file list for plain `fzf` and Ctrl+T
set -l _fzf_fd_base "fd --type f --hidden --exclude .git --exclude node_modules --exclude .cache --exclude .cargo --exclude go/pkg/mod --exclude .local/share"

set -gx FZF_DEFAULT_COMMAND $_fzf_fd_base
set -gx FZF_CTRL_T_COMMAND $_fzf_fd_base

# Alt+C directory search
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git --exclude node_modules --exclude .cache --exclude .local/share"

# Full-screen fzf.
# Important: no --height here. Full-screen mode clears sixel previews much better.
set -gx FZF_DEFAULT_OPTS "--layout=reverse --border --ansi --preview-window=right,60%,nowrap --preview='$HOME/.local/bin/fzf-preview {}' --bind='ctrl-/:toggle-preview'"

# Ctrl+T file picker preview
set -gx FZF_CTRL_T_OPTS "--preview='$HOME/.local/bin/fzf-preview {}' --preview-window=right,60%,nowrap --bind='ctrl-/:toggle-preview'"
