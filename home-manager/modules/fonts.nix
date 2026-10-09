{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # The one font for Ghostty, Konsole, Zed and Plasma's fixed-width text.
    nerd-fonts.jetbrains-mono
  ];
}
