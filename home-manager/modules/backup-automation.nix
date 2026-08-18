{ ... }:

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

  systemd.user.services.backup-on-mount = {
    Unit = {
      Description = "Run Restic backup when Linux-Backup is mounted";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/backup-on-mount";
    };
  };

  systemd.user.paths.backup-on-mount = {
    Unit = {
      Description = "Watch for Linux-Backup mount";
    };

    Path = {
      PathChanged = "/run/media/commander";
      Unit = "backup-on-mount.service";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.restic-maintenance = {
    Unit = {
      Description = "Prune old Restic snapshots and verify repository";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/restic-maintenance";
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
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/restic-deep-check";
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
