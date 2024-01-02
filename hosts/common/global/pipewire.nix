{
  lib,
  ...
}:

{
  # Set sound.enable to false, as it is only applicable to alsa
  sound.enable = lib.mkForce false;

  # rtkit is optional but recommended
  security.rtkit.enable = true;

  # Configure pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
}
