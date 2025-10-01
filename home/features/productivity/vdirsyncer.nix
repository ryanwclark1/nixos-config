{
  pkgs,
  config,
  ...
}: let
  pass = "${config.programs.password-store.package}/bin/pass";
in {
  home.packages = with pkgs; [vdirsyncer];

  # home.persistence = {
  #   "/persist/${config.home.homeDirectory}".directories = [
  #     "Calendars"
  #     "Contacts"
  #     ".local/share/vdirsyncer"
  #   ];
  # };

  xdg.configFile."vdirsyncer/config".text =
    /*
    ini
    */
    ''
      [general]
      status_path = "~/.local/share/vdirsyncer/status"

      [pair contacts]
      a = "contacts_local"
      b = "contacts_remote"
      collections = ["from a", "from b"]
      conflict_resolution = "b wins"

      [storage contacts_local]
      type = "filesystem"
      path = "~/Contacts"
      fileext = ".vcf"

      [storage contacts_remote]
      type = "carddav"
      url = "https://outlook.office365.com/dav/ryanc@accentvoice.com/contacts/"
      username = "ryanc@accentvoice.com"
      password.fetch = ["command", "${pass}", "smtp.office365.com/ryanc@accentvoice.com"]

      [pair calendars]
      a = "calendars_local"
      b = "calendars_remote"
      collections = ["from a", "from b"]
      metadata = ["color"]
      conflict_resolution = "b wins"

      [storage calendars_local]
      type = "filesystem"
      path = "~/Calendars"
      fileext = ".ics"

      [storage calendars_remote]
      type = "caldav"
      url = "https://outlook.office365.com/dav/ryanc@accentvoice.com/calendar/"
      username = "ryanc@accentvoice.com"
      password.fetch = ["command", "${pass}", "smtp.office365.com/ryanc@accentvoice.com"]
    '';

  systemd.user.services.vdirsyncer = {
    Unit = {
      Description = "vdirsyncer synchronization";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
    };
  };
  systemd.user.timers.vdirsyncer = {
    Unit = {
      Description = "Automatic vdirsyncer synchronization";
    };
    Timer = {
      OnBootSec = "30";
      OnUnitActiveSec = "5m";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
}