{
  lib,
  ...
}:

{
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    supportedLocales = lib.mkDefault [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      # Add other locales as needed
    ];
  };

  location.provider = "geoclue2";

  services.geoclue2 = {
    enable = true;
    submitData = false;
  };

  services.timesyncd = {
    enable = true;
    servers = [
      "time.cloudflare.com"
      "time.google.com"
      "pool.ntp.org"
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
  };

  time = {
    hardwareClockInLocalTime = false;
    timeZone = lib.mkDefault "America/Chicago";
  };
}
