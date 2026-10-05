{ lib, pkgs, ... }:

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
    jq

    # Media / terminal previews
    chafa

    # Archive / transfer
    unzip
    wget
    curl

    # Desktop CLI helpers
    dotool
    wl-clipboard
    trash-cli
    playerctl

    # System maintenance helpers
    topgrade
  ];

  # KDE misses new Nix desktop entries because store files share one fixed
  # timestamp, so rebuild its application cache after every switch.
  home.activation.refreshKdeAppCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -x /usr/bin/kbuildsycoca6 ]; then
      run /usr/bin/kbuildsycoca6 --noincremental
    fi
  '';
}
