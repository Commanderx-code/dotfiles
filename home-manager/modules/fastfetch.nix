{ ... }:

{
  programs.fastfetch.enable = true;

  xdg.configFile."fastfetch" = {
    source = ../../configs/fastfetch;
    recursive = true;
  };
}
