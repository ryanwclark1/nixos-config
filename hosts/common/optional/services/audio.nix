{
  pkgs,
  ...
}:

{
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
    # WirePlumber 0.5 expects .conf fragments under wireplumber.conf.d.
    # Prefer client-side Bluetooth roles so A2DP playback is stable and avoid
    # advertising headset gateway roles that can destabilize some headsets.
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-bluez-config.conf" ''
        monitor.bluez.properties = {
          bluez5.roles = [ a2dp_sink a2dp_source hsp_hs hfp_hf ]
          bluez5.codecs = [ sbc sbc_xq aac ]
          bluez5.enable-sbc-xq = true
          bluez5.enable-msbc = true
          bluez5.hfphsp-backend = "native"
        }
      '')
    ];
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 44100;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 512;
      };
    };
  };

  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  security.rtkit.enable = true;

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

  environment.systemPackages = with pkgs; [
    pwvucontrol
    pulsemixer
    pulseaudio  # Provides pactl command
    alsa-lib
    alsa-utils
    pavucontrol  # GUI audio control
  ];
}
