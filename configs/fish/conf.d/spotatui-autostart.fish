set -l spotatui_marker "$XDG_RUNTIME_DIR/spotatui-autostart"

if test "$TERM_PROGRAM" = "ghostty"; and test -f "$spotatui_marker"
    rm -f "$spotatui_marker"
    exec spotatui
end
