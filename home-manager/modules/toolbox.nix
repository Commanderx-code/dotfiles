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

  # The window, from the distribution's helix-toolbox-gui package, started
  # apart from the terminal so closing the terminal leaves it open. setsid
  # comes from the host's util-linux, as the package does.
  window = pkgs.writeShellApplication {
    name = "htbg";
    text = ''
      if ! command -v helix-toolbox-gui >/dev/null; then
        echo "htbg: the Helix Toolbox window is not installed; install the helix-toolbox-gui package." >&2
        exit 1
      fi
      setsid -f helix-toolbox-gui "$@" >/dev/null 2>&1
    '';
  };
in
{
  # Its short name, and its name before 1.7; htbg opens the window.
  home.packages =
    map launcher [
      "helix-toolbox"
      "htb"
      "helixforge"
    ]
    ++ [ window ];
}
