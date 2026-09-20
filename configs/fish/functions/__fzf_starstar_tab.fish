function __fzf_starstar_tab
    set -l token (commandline -t)

    # If the token ends with **
    if string match -qr '\*\*$' -- "$token"
        # Remove the trailing **
        commandline -t -- (string replace -r '\*\*$' '' -- "$token")

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
