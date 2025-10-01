{
  config,
  lib,
  pkgs,
  ...
}:

{
  accounts.calendar.accounts.accent = {
    name = "accent";
    local = {
      fileExt = ".ics";
      type = "filesystem";
    };
    primary = true;

    remote = {
      url = "http://localhost:1080/users/ryanc@accentvoice.com/calendar/";
      type = "caldav";
      userName = "ryanc@accentvoice.com";
      passwordCommand = [
        "cat"
        config.sops.secrets."accent-email/accent-email-password".path
      ];
    };

    vdirsyncer = {
      enable = true;
      collections = [ "calendar" ];
      itemTypes = [ "VEVENT" ];
      timeRange = {
        start = "datetime.now() - timedelta(days=7)";
        end = "datetime.now() + timedelta(days=30)";
      };
    };
  };

  systemd.user = {
    services = {
      calsync = {
        Unit = {
          Description = "calsync";
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.calsync} --noninteractive";
          ExecStopPost = "${lib.getExe pkgs.service-status} calsync";
        };
      };
    };

    timers = {
      calsync = {
        Unit = {
          Description = "regular calsync";
          After = "network-online.target";
        };

        Timer = {
          Unit = "calsync.service";
          OnCalendar = "0/2:00:00";
          AccuracySec = "10min";
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };

}
