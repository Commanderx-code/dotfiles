{ machine, lib, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      lg = "lazygit";

      hms = "home-manager switch --flake ${lib.escapeShellArg "${machine.dotfilesDirectory}/home-manager#${machine.username}"}";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # Keep your custom Fish configuration.
  xdg.configFile."fish/conf.d" = {
    source = ../../configs/fish/conf.d;
    recursive = true;
  };

  xdg.configFile."fish/functions" = {
    source = ../../configs/fish/functions;
    recursive = true;
  };
}
