function fish_user_key_bindings
    # Keep default + fzf keybinds if available
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end

    # --- Your custom binds ---
    bind \cp fzf_open_file
    bind \cf fzf_rg_search

    # Switch history from Ctrl-R to Ctrl-H
    bind \ch fzf-history-widget

    # Optional: unbind Ctrl-R from fzf-history (so it stops opening history)
    # (This makes Ctrl-R do nothing unless you bind it to something else)
    bind \cr ""

    # Tab behavior: if token ends with ** -> trigger fzf-file-widget
    bind \t __fzf_starstar_tab
end

function __fzf_starstar_tab
    set -l token (commandline -t)

    # If the token ends with **
    if string match -qr '\*\*$' -- $token
        # Remove the trailing **
        commandline -t (string replace -r '\*\*$' '' -- $token)

        # Prefer official fzf widget if present, else fall back to your opener
        if functions -q fzf-file-widget
            fzf-file-widget
        else
            fzf_open_file
        end
        return
    end

    # Normal tab completion if not **
    commandline -f complete
end
