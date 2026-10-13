{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Konsole, Zed and Plasma's fixed-width text.
    nerd-fonts.jetbrains-mono
    # Ghostty.
    nerd-fonts.meslo-lg
  ];
}
