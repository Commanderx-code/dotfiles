{ config, pkgs, ... }:

let
  c = config.commander.theme.colors;
  # The prompt's layout is shared from Myfish (see FISH-SYNC.md); its colours are
  # named, so the palette chosen with `rice` is swapped in here.
  shared = builtins.fromTOML (builtins.readFile ../../configs/starship/starship.toml);
  # Present while `tdprompt off` has hidden the score segment.
  nflOffFlag = "$HOME/.local/state/touchdown/prompt-off";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "tdprompt" ''
      flag="${nflOffFlag}"
      hide() { mkdir -p "$(dirname "$flag")" && touch "$flag"; }
      case "''${1:-toggle}" in
        on) rm -f "$flag" ;;
        off) hide ;;
        toggle) if [ -e "$flag" ]; then rm -f "$flag"; else hide; fi ;;
        *) echo "usage: tdprompt [on|off]" >&2; exit 2 ;;
      esac
      if [ -e "$flag" ]; then echo "prompt score off"; else echo "prompt score on"; fi
    '')
  ];

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = shared // {
      # Ghostty draws the logo from Symbols Nerd Font, wide enough to fill the
      # space after it; a second space keeps it off the username.
      os = shared.os // {
        format = "[$symbol  ]($style)";
      };
      # Touchdown's favorite-team score, right-aligned on the first line. It
      # prints from its local cache, so the prompt never waits on ESPN.
      right_format = "\${custom.nfl}";
      custom.nfl = {
        command = "td -status -live";
        when = "command -v td && [ ! -e \"${nflOffFlag}\" ]";
        # The outer group drops the icon when there is no live game to show.
        format = "([🏈 $output]($style) )";
        style = "bold green";
        shell = [ "sh" ];
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
