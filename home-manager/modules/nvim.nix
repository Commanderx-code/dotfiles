{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  xdg.configFile."nvim" = {
    source = ../../configs/nvim;
    recursive = true;
  };
}
