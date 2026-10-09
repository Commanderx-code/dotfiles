{ ... }:

{
  imports = [
    ./zellij.nix
    ./terminal-trials.nix
  ];

  # The Ghostty theme, topbar.css and Konsole's Commander colours come from modules/theme.nix.
  xdg.configFile."ghostty/spotatui.conf".source = ../../configs/ghostty/spotatui.conf;

  # fzf preview helper used by Fish/fzf.
  home.file.".local/bin/fzf-preview" = {
    source = ../../configs/scripts/fzf-preview;
    executable = true;
  };

  home.file.".local/bin/fzf-rg-results" = {
    source = ../../configs/scripts/fzf-rg-results;
    executable = true;
  };

  home.file.".local/bin/clickpaste" = {
    source = ../scripts/clickpaste.py;
    executable = true;
  };

  # Konsole global configuration.
  xdg.configFile."konsolerc".source = ../../configs/konsole/konsolerc;

  # Konsole profile; Sweet stays available as an alternative scheme.
  home.file.".local/share/konsole/Garuda.profile".source = ../../configs/konsole/Garuda.profile;

  home.file.".local/share/konsole/Sweet.colorscheme".source = ../../configs/konsole/Sweet.colorscheme;
}
