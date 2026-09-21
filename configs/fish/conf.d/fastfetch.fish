# Print once. Repainting a fetch taller than the window on WINCH repeatedly
# pushes copies into scrollback and competes with Fish's prompt renderer.
if not status is-interactive
    return
end
# Keep startup artwork in the outer Ghostty/Konsole window. Zellij's pinned
# version cannot display Kitty images; run fastfetch --logo none there.
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
# Use the terminal grid to recognize narrow/short snapped windows. Keep the
# greeting, but only auto-run Fastfetch when there is enough room for it.
# Manual fastfetch remains available at any size.
if test "$COLUMNS" -ge 100; and test "$LINES" -ge 24; and command -q fastfetch
    printf '\n\n'
    fastfetch
end
