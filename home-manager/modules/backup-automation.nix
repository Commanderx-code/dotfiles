{
  machine,
  pkgs,
  lib,
  ...
}:

let
  offsite = (machine.offsiteRepository or "") != "";
in
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

  home.file.".local/bin/backup-offsite" = {
    source = ../scripts/backup-offsite.fish;
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

  # Backups only run when the drive is connected, so nothing fails while it
  # stays unplugged. This says so once the last backup is a few days old.
  systemd.user.services.backup-reminder = {
    Unit = {
      Description = "Remind about an overdue backup";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      Environment = [ "BACKUP_NOTIFIER=${pkgs.libnotify}/bin/notify-send" ];
      ExecStart = "%h/.local/bin/backup-health --remind";
    };
  };

  systemd.user.timers.backup-reminder = {
    Unit = {
      Description = "Daily check for an overdue backup";
    };

    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };

    Install = {
      WantedBy = [ "timers.target" ];
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

  # The offsite repository needs no drive, so it runs on a clock: a nightly
  # backup, weekly pruning and a monthly data sample, each with its own
  # failure notification. Nothing here exists until machine.json names it.
  systemd.user.services.backup-offsite = lib.mkIf offsite {
    Unit = {
      Description = "Nightly Restic backup to the offsite repository";
      OnFailure = [ "backup-failure@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/backup-offsite";
    };
  };

  systemd.user.timers.backup-offsite = lib.mkIf offsite {
    Unit = {
      Description = "Nightly offsite backup";
    };

    Timer = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.restic-maintenance-offsite = lib.mkIf offsite {
    Unit = {
      Description = "Prune old offsite Restic snapshots and verify repository";
      OnFailure = [ "backup-failure@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/restic-maintenance --offsite --if-due";
    };
  };

  systemd.user.timers.restic-maintenance-offsite = lib.mkIf offsite {
    Unit = {
      Description = "Weekly offsite Restic repository maintenance";
    };

    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.restic-deep-check-offsite = lib.mkIf offsite {
    Unit = {
      Description = "Deep offsite Restic repository integrity check";
      OnFailure = [ "backup-failure@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/restic-deep-check --offsite --if-due";
    };
  };

  systemd.user.timers.restic-deep-check-offsite = lib.mkIf offsite {
    Unit = {
      Description = "Monthly deep offsite Restic integrity check";
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
