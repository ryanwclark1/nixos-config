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
  services.geoclue2 = {
    enable = true;
    submitData = false;
  };
  services.timesyncd = {
    enable = true;
  };
  location.provider = "geoclue2";
  time.timeZone = lib.mkDefault "America/Chicago";
}
