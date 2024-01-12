# ./host/common/audio.nix

{
  lib,
  config,
  ...
}:
with lib;

{
  options.audio.enable = mkEnableOption "audio settings";

  config = mkIf config.audio.enable {
    # sound.enable = lib.mkForce false;
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

    # Configure pipewire
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      # wireplumber.enable = true;
      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };
}
