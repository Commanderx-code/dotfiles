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
  ./modules/terminal.nix
  ./modules/backup-automation.nix
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

home.file.".local/bin/backup-system-state" = {
  source = ./scripts/backup-system-state.fish;
  executable = true;
};

home.file.".local/bin/backup-secrets" = {
  source = ./scripts/backup-secrets.fish;
  executable = true;
};

home.file.".local/bin/backup-personal" = {
  source = ./scripts/backup-personal.fish;
  executable = true;
};
home.file.".local/bin/backup-everything" = {
  source = ./scripts/backup-everything.fish;
  executable = true;
};
home.file.".local/bin/backup-restic-credential" = {
  source = ./scripts/backup-restic-credential.fish;
  executable = true;
};
home.file.".local/bin/restore-system" = {
  source = ./scripts/restore-system.fish;
  executable = true;
};
home.file.".local/bin/pkg-owner" = {
  source = ./scripts/pkg-owner.fish;
  executable = true;
};

home.file.".local/bin/pkg-install" = {
  source = ./scripts/pkg-install.fish;
  executable = true;
};

home.file.".local/bin/hm-rebuild" = {
  source = ./scripts/hm-rebuild.fish;
  executable = true;
};
}
