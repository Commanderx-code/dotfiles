{ pkgs, ... }:

{
  # HelixForge from its published releases, checked on every start.
  # An executable ~/.local/bin/helixforge is run instead when present.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "helixforge";
      runtimeInputs = [
        pkgs.curl
        pkgs.coreutils
      ];
      text = ''
        exec ${pkgs.bash}/bin/bash ${../scripts/toolbox-launcher.sh} "$@"
      '';
    })
  ];
}
