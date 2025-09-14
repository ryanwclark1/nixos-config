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
    # Enable Bluetooth audio support (requires bluetooth.nix to be imported)
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
        bluez_monitor.properties = {
          ["bluez5.enable-sbc-xq"] = true,
          ["bluez5.enable-msbc"] = true,
          ["bluez5.enable-hw-volume"] = true,
          ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
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
