# Print once. Repainting a fetch taller than the window on WINCH repeatedly
# pushes copies into scrollback and competes with Fish's prompt renderer.
if not status is-interactive
    return
end
# The fixed-width welcome does not fit multiplexer panes; keep it in the
# outer Ghostty/Konsole window. Run fastfetch manually inside Zellij if wanted.
if set -q ZELLIJ
    return
end
if not set -q KONSOLE_VERSION; and test "$TERM_PROGRAM" != ghostty
    return
end

# Unregister the previous version if this file is sourced in an existing shell.
functions -e __commander_welcome_resize __commander_welcome_stop __commander_welcome_draw
set -e __commander_welcome_active
set -e __commander_welcome_busy
set -e __commander_welcome_size

set_color normal
printf 'Hello, Commander '
set_color yellow
printf '\n'
set_color normal
if command -q fastfetch
    printf '\n\n'
    fastfetch
end
