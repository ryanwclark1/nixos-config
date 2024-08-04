{
  pkgs,
  ...
}:

{
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    package = pkgs.pipewire;
    # Enabling system-wide PipeWire is however not recommended and disabled by default according to https://github.com/PipeWire/pipewire/blob/master/NEWS
    systemWide = false;
    socketActivation = true;
    # Opens UDP/6001-6002, required by RAOP/Airplay for timing and control data.
    raopOpenFirewall = false;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };
}
