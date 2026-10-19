{ pkgs, ... }:

let
  # Helix Toolbox (HelixForge before 1.7) from its published releases,
  # checked on every start. An executable ~/.local/bin/helix-toolbox is run
  # instead when present.
  launcher =
    name:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.curl
        pkgs.coreutils
      ];
      text = ''
        exec ${pkgs.bash}/bin/bash ${../scripts/toolbox-launcher.sh} "$@"
      '';
    };
in
{
  # Its short name, and its name before 1.7.
  home.packages = map launcher [
    "helix-toolbox"
    "htb"
    "helixforge"
  ];
}
