{ pkgs, ... }:

{
  home.packages = with pkgs; [
    eza
    bat
    fd
    ripgrep
    btop
    lazygit
    chafa
    jq
    unzip
    wget
    curl
  ];
}
