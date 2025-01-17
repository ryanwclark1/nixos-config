{
  lib,
  pkgs,
  ...
}:

{
  services.mpd = {
    enable = true;
    user = "administrator";
    startWhenNeeded = false;
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "My PipeWire Output"
      }
    '';
    # Optional:
    network = {
      listenAddress = "any"; # if you want to allow non-localhost connections
      port = 6600;
    };
  };

  hardware.pulseaudio.enable = lib.mkForce false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    package = pkgs.pipewire;
    # Enabling system-wide PipeWire is not recommended and disabled by default according to https://github.com/PipeWire/pipewire/blob/master/NEWS
    socketActivation = true;
    # Opens UDP/6001-6002, required by RAOP/Airplay for timing and control data.
    raopOpenFirewall = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;
    };
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 44100;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 512;
      };
    };
  };

  environment.systemPackages = with pkgs; [
      pwvucontrol
      pulsemixer
      alsa-lib
      alsa-utils
  ];

  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];
}
