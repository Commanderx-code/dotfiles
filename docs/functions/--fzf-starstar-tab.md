---
title: __fzf_starstar_tab
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/__fzf_starstar_tab.fish
runtime: ~/.config/fish/functions/__fzf_starstar_tab.fish
tags: fish function
status: active
criticality: normal
last_verified: 2026-08-26
---
# `__fzf_starstar_tab`

## Purpose
Tab: if token ends with ** use fzf-file-widget, else normal completion

## Usage
Inspect the live definition with:
```fish
type __fzf_starstar_tab
functions __fzf_starstar_tab
```

## Modify / Apply
```fish
nvim ~/dotfiles/configs/fish/functions/__fzf_starstar_tab.fish
cd ~/dotfiles
git add configs/fish/functions/__fzf_starstar_tab.fish
hms
```

## Syntax Check
```fish
fish -n ~/dotfiles/configs/fish/functions/__fzf_starstar_tab.fish
```

## Current Implementation
```fish
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
```
