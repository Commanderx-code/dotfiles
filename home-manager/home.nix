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
    userName = "Matthew March";
    userEmail = "dirtyprodigy@protonmail.com";
  };

  programs.fish.enable = true;
  programs.starship.enable = true;
}
