{ pkgs, ... }:

{
  # Commander Toolbox from its published releases, checked on every start.
  # An executable ~/.local/bin/commander-toolbox is run instead when present.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "commander-toolbox";
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
