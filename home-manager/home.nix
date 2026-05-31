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
  ];

  programs.git = {
    enable = true;
    userName = "Commanderx-code";
    userEmail = "65996567+Commanderx-code@users.noreply.github.com";
  };

  programs.fish.enable = true;
  programs.starship.enable = true;
}
