{
  machine,
  lib,
  nixpkgs,
  ...
}:

{
  imports = [
    ./modules/machine.nix
    ./modules/repo-sync.nix
    ./modules/fonts.nix
    ./modules/theme.nix
    ./modules/plasma.nix
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/fish.nix
    ./modules/starship.nix
    ./modules/fastfetch.nix
    ./modules/nvim.nix
    ./modules/zed.nix
    ./modules/topgrade.nix
    ./modules/terminal.nix
    ./modules/zapfast.nix
    ./modules/toolbox.nix
    ./modules/backup-automation.nix
  ];
  home.username = machine.username;
  home.homeDirectory = machine.homeDirectory;

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # `nix shell nixpkgs#…`, `nix run` and `nix search` use the nixpkgs this
  # flake pins, not the global registry's (FlakeHub's weekly one), so they get
  # the same versions Home Manager installs.
  nix.registry.nixpkgs.flake = nixpkgs;

  # No "unread news items" reminder after each rebuild; `home-manager news` still shows them.
  news.display = "silent";

  # Every rebuild leaves a generation behind. Once a week, drop those older
  # than two weeks and the store paths only they used; the current one stays.
  services.home-manager.autoExpire = {
    enable = true;
    frequency = "weekly";
    timestamp = "-14 days";
    store.cleanup = true;
    store.options = "--delete-older-than 14d";
  };

  # Commands installed into ~/.local/bin, each from a script in ./scripts.
  home.file =
    lib.mapAttrs'
      (
        name: source:
        lib.nameValuePair ".local/bin/${name}" {
          inherit source;
          executable = true;
        }
      )
      {
        backup-sddm = ./scripts/backup-sddm.sh;
        restore-sddm = ./scripts/restore-sddm.sh;
        restore-grub = ./scripts/restore-grub.sh;
        restore-plymouth = ./scripts/restore-plymouth.sh;
        restore-limine = ./scripts/restore-limine.sh;
        backup-system-state = ./scripts/backup-system-state.fish;
        backup-secrets = ./scripts/backup-secrets.fish;
        backup-personal = ./scripts/backup-personal.fish;
        backup-everything = ./scripts/backup-everything.fish;
        backup-restic-credential = ./scripts/backup-restic-credential.fish;
        restore-system = ./scripts/restore-system.fish;
        pkg-owner = ./scripts/pkg-owner.fish;
        pkg-install = ./scripts/pkg-install.fish;
        hm-rebuild = ./scripts/hm-rebuild.fish;
        rice = ./scripts/rice.fish;
        backup-app-inventory = ./scripts/backup-app-inventory.fish;
        restore-apps = ./scripts/restore-apps.fish;
      };

  # Garuda's own ~/.config/environment.d/garuda.conf names programs this
  # workstation does not use: FireDragon, which is not installed (so gh and other
  # command-line tools failed to open a page), micro as EDITOR, and a VISUAL
  # value in curly quotes that no program can run. These files load in name
  # order and later ones win; this one sorts after garuda.conf. The editor
  # matches conf.d/exports.fish. Takes effect at the next login.
  xdg.configFile."environment.d/zz-workstation.conf".text = ''
    BROWSER=brave-origin
    EDITOR=nvim
    VISUAL=nvim
  '';
}
