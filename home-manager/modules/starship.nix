{ config, ... }:

let
  c = config.commander.theme.colors;
  # The prompt's layout is shared from Myfish (see FISH-SYNC.md); its colours are
  # named, so the palette chosen with `rice` is swapped in here.
  shared = builtins.fromTOML (builtins.readFile ../../configs/starship/starship.toml);
in
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = shared // {
      # Ghostty's `window-padding-color = extend` paints the left padding in the
      # color of a row's first cell; a plain leading cell keeps the bar's gray
      # out of the padding.
      format = " " + shared.format;
      # Ghostty draws the logo from Symbols Nerd Font, wide enough to fill the
      # space after it; a second space keeps it off the username.
      os = shared.os // {
        format = "[$symbol  ]($style)";
      };
      palette = "commander";
      palettes.commander = {
        prompt_text = c.text;
        prompt_dark = c.base;
        alert = c.red;
        user = c.surface;
        directory = c.overlay;
        git = c.muted;
        language = c.purple;
        docker = c.cyan;
        time = c.blue;
      };
    };
  };
}
