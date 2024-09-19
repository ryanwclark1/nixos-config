{
  pkgs,
  ...
}:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    package = pkgs.pipewire;
    # Enabling system-wide PipeWire is not recommended and disabled by default according to https://github.com/PipeWire/pipewire/blob/master/NEWS
    socketActivation = true;
    # Opens UDP/6001-6002, required by RAOP/Airplay for timing and control data.
    raopOpenFirewall = false;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;
    };
    pulse.enable = false;
    jack.enable = false;
  };

  environment.systemPackages = with pkgs; [
      pwvucontrol
      alsa-lib
      alsa-utils
  ];
}
