{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  voxtypePkg = inputs.voxtype.packages.${system}.rocm;
  
  # Manually generate the config file since we're bypassing the module to avoid service conflicts
  configFile = pkgs.writeText "voxtype-config.toml" ''
    engine = "whisper"
    state_file = "auto"

    [hotkey]
    enabled = false
    
    [audio]
    device = "default"
    sample_rate = 16000
    max_duration_secs = 60

    [whisper]
    model = "/nix/store/xv0p63cmjjmj6s57yvzygrm00liyml7b-ggml-medium.en.bin"
    language = "en"
    flash_attention = true
    
    [output]
    mode = "type"
    fallback_to_clipboard = true
  '';
in
{
  home.packages = with pkgs; [
    voxtypePkg
    wtype
    wl-clipboard
  ];

  systemd.user.services.voxtype = {
    Unit = {
      Description = "VoxType push-to-talk voice-to-text daemon";
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      ExecStart = "${voxtypePkg}/bin/voxtype --config ${configFile} daemon";
      Environment = [
        "HSA_OVERRIDE_GFX_VERSION=11.0.0"
        "PATH=${lib.makeBinPath [ pkgs.wtype pkgs.wl-clipboard ]}:/run/current-system/sw/bin"
      ];
      ExecSearchPath = "${pkgs.wtype}/bin:${pkgs.wl-clipboard}/bin";
      Restart = "always";
      RestartSec = "3";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
