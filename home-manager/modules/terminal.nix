{ ... }:

{
  # fzf preview helper used by Fish/fzf.
  home.file.".local/bin/fzf-preview" = {
    source = ../../configs/scripts/fzf-preview;
    executable = true;
  };

  # Konsole global configuration.
  xdg.configFile."konsolerc".source =
    ../../configs/konsole/konsolerc;

  # Konsole profile and color scheme.
  home.file.".local/share/konsole/Garuda.profile".source =
    ../../configs/konsole/Garuda.profile;

  home.file.".local/share/konsole/Sweet.colorscheme".source =
    ../../configs/konsole/Sweet.colorscheme;
}
