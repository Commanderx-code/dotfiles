function spotatui-ghostty --description 'Open spotatui in a new Ghostty window'
    touch "$XDG_RUNTIME_DIR/spotatui-autostart"
    ghostty +new-window
end
