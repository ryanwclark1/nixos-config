{
  ...
}:

{
  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };
}
