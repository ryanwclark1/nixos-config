{
  config,
  pkgs,
  ...
}:

{
  accounts.contact.accounts.accent = {
    name = "accent";
    local = {
      type = "filesystem";
      fileExt = ".vcf";
    };

    # remote = {
    #   url = "http://localhost:1080/users/ryanc@accentvoice.com/calendar/";
    #   type = "caldav";
    #   userName = "ryanc@accentvoice.com";
    #   passwordCommand = [
    #     "cat"
    #     config.sops.secrets."accent-email/accent-email-password".path
    #   ];
    # };

    # vdirsyncer = {
    #   enable = true;
    #   collections = [ "calendar" ];
    #   itemTypes = [ "VEVENT" ];
    #   timeRange = {
    #     start = "datetime.now() - timedelta(days=7)";
    #     end = "datetime.now() + timedelta(days=30)";
    #   };
    # };
  };
}
