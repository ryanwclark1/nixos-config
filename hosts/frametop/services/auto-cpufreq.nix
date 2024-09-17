{
  lib,
  ...
}:

{
  services.auto-cpufreq = {
    enable = lib.mkDefault true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };
}