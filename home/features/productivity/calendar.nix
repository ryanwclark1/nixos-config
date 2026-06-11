{
  config,
  lib,
  pkgs,
  ...
}:

let
  khalNoDocs = pkgs.khal.overridePythonAttrs (old: {
    # khal docs currently fail under Sphinx 9 during doctree post-processing.
    sphinxBuilders = [ ];
    nativeBuildInputs = lib.filter (
      pkg:
      let
        pkgName = pkg.pname or (lib.getName pkg);
      in
      !(lib.hasSuffix "sphinx-hook" pkgName)
      && pkgName != "sphinx-rtd-theme"
      && pkgName != "sphinxcontrib-newsfeed"
    ) old.nativeBuildInputs;
    postInstall = (old.postInstall or "") + ''
      # Keep expected multi-output derivation shape when docs are disabled.
      mkdir -p "$doc/share/doc/khal"
      mkdir -p "$man/share/man/man1"
    '';
  });
in
{
  home.packages = with pkgs; [
    khalNoDocs
  ];

  accounts.calendar = {
    basePath = "${config.home.homeDirectory}/Calendars";
    accounts.accent = {
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

    # systemd.user = {
    #   services = {
    #     calsync = {
    #       Unit = {
    #         Description = "calsync";
    #       };

    #       Service = {
    #         Type = "oneshot";
    #         ExecStart = "${lib.getExe pkgs.calsync} --noninteractive";
    #         ExecStopPost = "${lib.getExe pkgs.service-status} calsync";
    #       };
    #     };
    #   };

    #   timers = {
    #     calsync = {
    #       Unit = {
    #         Description = "regular calsync";
    #         After = "network-online.target";
    #       };

    #       Timer = {
    #         Unit = "calsync.service";
    #         OnCalendar = "0/2:00:00";
    #         AccuracySec = "10min";
    #       };

    #       Install = {
    #         WantedBy = [ "timers.target" ];
    #       };
    #     };
    #   };
    # };
  };

  # home.file.".config/khal/config".text =
  #   /*
  #   toml
  #   */
  #   ''
  #     [calendars]

  #     [[calendars]]
  #     path = ~/Calendars/*
  #     type = discover

  #     [locale]
  #     timeformat = %H:%M
  #     dateformat = %d/%m/%Y
  #   '';

}
