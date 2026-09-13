{ machine, pkgs, ... }:

{
  home.file.".local/bin/backup-on-mount" = {
    source = ../scripts/backup-on-mount.fish;
    executable = true;
  };

  home.file.".local/bin/restic-maintenance" = {
    source = ../scripts/restic-maintenance.fish;
    executable = true;
  };

  home.file.".local/bin/restic-deep-check" = {
    source = ../scripts/restic-deep-check.fish;
    executable = true;
  };

  systemd.user.services."backup-failure@" = {
    Unit.Description = "Notify about backup failure in %i";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical --expire-time=0 --app-name=Backups 'Backup service failed' '%i failed. Run backup-health and inspect its journal for details.'";
    };
  };

  systemd.user.services.backup-on-mount = {
    Unit = {
      Description = "Run Restic backup when the backup drive is mounted";
      OnFailure = [ "backup-failure@%n.service" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/backup-on-mount";
    };
  };

  systemd.user.paths.backup-on-mount = {
    Unit = {
      Description = "Watch for backup mount";
    };

    Path = {
      PathChanged = builtins.dirOf machine.backupMount;
      Unit = "backup-on-mount.service";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.restic-maintenance = {
    Unit = {
      Description = "Prune old Restic snapshots and verify repository";
      OnFailure = [ "backup-failure@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/restic-maintenance --if-due";
    };
  };

  systemd.user.timers.restic-maintenance = {
    Unit = {
      Description = "Weekly Restic repository maintenance";
    };

    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.restic-deep-check = {
    Unit = {
      Description = "Deep Restic repository integrity check";
      OnFailure = [ "backup-failure@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/restic-deep-check --if-due";
    };
  };

  systemd.user.timers.restic-deep-check = {
    Unit = {
      Description = "Monthly deep Restic integrity check";
    };

    Timer = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
