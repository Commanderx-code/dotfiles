# fzf keybindings + completions for fish (works on Debian/Ubuntu/Zorin and Arch)
# Safe: only loads if the example scripts exist.

# Debian/Ubuntu/Zorin path (fzf package usually installs these)
if test -f /usr/share/doc/fzf/examples/key-bindings.fish
    source /usr/share/doc/fzf/examples/key-bindings.fish
end

if test -f /usr/share/doc/fzf/examples/completion.fish
    source /usr/share/doc/fzf/examples/completion.fish
end

# Arch path (commonly installed here)
if test -f /usr/share/fzf/key-bindings.fish
    source /usr/share/fzf/key-bindings.fish
end

if test -f /usr/share/fzf/completion.fish
    source /usr/share/fzf/completion.fish
end

# If fzf_configure_bindings exists (from key-bindings), set sane defaults
if type -q fzf_configure_bindings
    # Ctrl-R history, Ctrl-T file widget, Alt-C cd widget
    fzf_configure_bindings --history=\cr --directory=\ec --variables=\cv --git_log=\cg
end

