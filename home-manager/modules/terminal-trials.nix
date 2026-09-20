{ pkgs, ... }:
let
  tools = import ../terminal-tools.nix { inherit pkgs; };
in
{
  home.packages = [
    tools.netwatch
    tools.tfm
    tools.cassette
    pkgs.librespot
  ];
  # Keep app settings writable. Spotify credentials never enter the Nix store.
}
