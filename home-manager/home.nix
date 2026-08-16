{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/fish.nix
    ./modules/starship.nix
    ./modules/fastfetch.nix
    ./modules/nvim.nix
    ./modules/topgrade.nix
  ];

  home.username = "commander";
  home.homeDirectory = "/home/commander";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.file.".local/bin/backup-sddm" = {
    source = ./scripts/backup-sddm.sh;
    executable = true;
  };

  home.file.".local/bin/restore-sddm" = {
    source = ./scripts/restore-sddm.sh;
    executable = true;
  };
}
