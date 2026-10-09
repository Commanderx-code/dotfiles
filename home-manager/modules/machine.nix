{ machine, lib, ... }:
{
  home.file.".local/share/dotfiles/encrypted-backup.py".source = ../scripts/encrypted-backup.py;
  home.file.".local/share/dotfiles/restore-system-files.py".source =
    ../scripts/restore-system-files.py;
  xdg.configFile."dotfiles/machine.json".source = ../machine.json;
  # Sorts before conf.d/fastfetch.fish, which greets by this name.
  xdg.configFile."fish/conf.d/00-machine.fish".text = ''
    # Generated from home-manager/machine.json by modules/machine.nix.
    set -g COMMANDER_NAME ${lib.escapeShellArg machine.displayName}
  '';
  home.file.".local/share/dotfiles/settings.fish".source = ../scripts/lib/settings.fish;
  home.file.".local/bin/backup-health" = {
    source = ../scripts/backup-health.fish;
    executable = true;
  };
  home.file.".local/share/dotfiles/backup-health.py".source = ../scripts/backup-health.py;
  home.file.".local/bin/restic-job" = {
    source = ../scripts/restic-job.py;
    executable = true;
  };
  home.file.".local/bin/snapshot-transaction" = {
    source = ../scripts/snapshot-transaction.py;
    executable = true;
  };
  home.file.".local/bin/snapshot-metadata" = {
    source = ../scripts/snapshot-metadata.py;
    executable = true;
  };
}
