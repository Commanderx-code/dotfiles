# -----------------------------
# FZF (Fish)
# -----------------------------

# Load fzf fish keybindings + completion (Arch locations + fallback)
for f in \
    /usr/share/fzf/key-bindings.fish \
    /usr/share/fzf/completion.fish \
    /usr/share/doc/fzf/examples/key-bindings.fish \
    /usr/share/doc/fzf/examples/completion.fish
    if test -f $f
        source $f
    end
end

# Default file list for plain `fzf` (fast, sane excludes)
set -l _fzf_fd_base "fd --type f --hidden --exclude .git --exclude node_modules --exclude .cache --exclude .cargo --exclude go/pkg/mod --exclude .local/share"

# If you want to exclude other big dirs, add them here:
# --exclude .npm --exclude .rustup --exclude .mozilla --exclude .var --exclude .local/state

set -gx FZF_DEFAULT_COMMAND $_fzf_fd_base
set -gx FZF_CTRL_T_COMMAND  $_fzf_fd_base

# Alt-C: directory search (no --follow to avoid slow symlink explosions)
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git --exclude node_modules --exclude .cache --exclude .local/share"

# Preview using your __preview_file function
set -gx FZF_DEFAULT_OPTS "--height 80% --layout=reverse --border --ansi --preview-window=right,60%,wrap --preview '__preview_file {}'"
