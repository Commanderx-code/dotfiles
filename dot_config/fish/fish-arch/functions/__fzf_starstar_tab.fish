function __fzf_starstar_tab --description "Tab: if token ends with ** use fzf-file-widget, else normal completion"
    set -l tok (commandline -t)

    # If current token ends with "**", trigger fzf file picker
    if string match -rq '\*\*$' -- "$tok"
        # Remove the trailing ** from the token before inserting the chosen path
        set -l cleaned (string replace -r '\*\*$' '' -- "$tok")
        commandline -t -- "$cleaned"

        # Use fzf's built-in widget (provided by fzf_key_bindings)
        commandline -f fzf-file-widget
        return
    end

    # Otherwise: behave like normal Tab completion
    commandline -f complete
end
