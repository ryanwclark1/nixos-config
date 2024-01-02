# ./host/frametop/power-mangement.nix
{
  services = {
    power-profiles-daemon = {
      enable = true;
    };
  };

  # services.tlp.enable = true;
  services.acpid.enable = true;

  # using auto-cpufreq for now
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        battery = "powersave";
        turbo = "never";
      };

      charger = {
        battery = "performance";
        turbo = "auto";
      };
    };
  };

  boot.kernelParams = [
    "intel_pstate=disable"
  ];
}