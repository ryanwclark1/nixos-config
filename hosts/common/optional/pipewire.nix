{
  pkgs,
  ...
}:

{
  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    package = pkgs.pipewire;
    # Enabling system-wide PipeWire is however not recommended and disabled by default according to https://github.com/PipeWire/pipewire/blob/master/NEWS
    systemWide = false;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };
}
