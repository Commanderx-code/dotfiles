{ pkgs, ... }:

{
  programs.fastfetch.enable = true;

  home.packages = [
    (pkgs.writeShellApplication {
      name = "commander-fastfetch-layout";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        exec python3 ${../scripts/fastfetch-layout.py} "$@"
      '';
    })
  ];

  xdg.configFile."fastfetch" = {
    source = ../../configs/fastfetch;
    recursive = true;
  };
}
