{
  lib,
  ...
}:

{
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
    ];
  };

  location.provider = "geoclue2";

  services = {
    geoclue2 = {
      enable = true;
      submitData = false;
    };
    timesyncd = {
      enable = true;
    };
  };

  time = {
    hardwareClockInLocalTime = false;
    timeZone = lib.mkDefault "America/Chicago";
  };
}
