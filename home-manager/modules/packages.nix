{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core shell / file tools
    eza
    bat
    fd
    ripgrep
    broot
    yazi
    nnn

    # Monitoring / process tools
    btop
    procs

    # Git / development helpers
    lazygit

    # Data / scripting
    python3
    jq

    # Media / terminal previews
    chafa

    # Archive / transfer
    unzip
    wget
    curl

    # Desktop CLI helpers
    trash-cli
    playerctl

    # System maintenance helpers
    topgrade
  ];
}
