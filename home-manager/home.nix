{ config, pkgs, ... }:

{
  home.username = "commander";
  home.homeDirectory = "/home/commander";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide
    btop
    fastfetch
    lazygit
    chafa
    jq
    unzip
    wget
    curl
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "Matthew March";
      user.email = "dirtyprodigy@protonmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

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
      hms = "home-manager switch";
    };

    interactiveShellInit = ''
      zoxide init fish | source
      fzf --fish | source
    '';
  };

  programs.fastfetch = {
    enable = true;
  };
}
