function fish_user_key_bindings
    # Home Manager initializes fzf; retain its standard widgets.
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end

    bind \cp fzf_open_file
    bind \cf fzf_rg_search
    bind \ch fzf-history-widget
    bind \cr ""
    bind \t __fzf_starstar_tab
end
