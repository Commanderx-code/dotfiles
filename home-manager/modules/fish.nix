{ ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "eza -lah --icons";
      la = "eza -la --icons";
      lt = "eza --tree --level=2 --icons";

      cat = "bat";
      grep = "rg";

      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      lg = "lazygit";

      update = "sudo pacman -Syu && paru -Sua";

      hms = "home-manager switch --flake ~/dotfiles/home-manager#commander";
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
