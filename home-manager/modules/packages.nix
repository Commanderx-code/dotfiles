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
  # Activation runs with a PATH of Nix store tools only. KDE drops every
  # application whose TryExec it cannot find there, which hid Konsole, Zed, mpv
  # and others from the launcher until the cache was next rebuilt, so the
  # rebuild gets the directories a login session has.
  home.activation.refreshKdeAppCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -x /usr/bin/kbuildsycoca6 ]; then
      PATH="$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH" \
        run /usr/bin/kbuildsycoca6 --noincremental
    fi
  '';
}
