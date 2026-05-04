{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.voxtype.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    wtype
    wl-clipboard
  ];

  programs.voxtype = {
    enable = true;
    package = inputs.voxtype.packages.${system}.rocm;
    model.name = "medium.en";
    service.enable = false;
    settings = {
      hotkey.enabled = true;
      hotkey.key = "PAUSE";
      whisper.language = "en";
      output = {
        mode = "type";
        fallback_to_clipboard = true;
      };
    };
  };

  systemd.user.services.voxtype = {
    Unit = {
      Description = "VoxType push-to-talk voice-to-text daemon";
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      Environment = [
        "HSA_OVERRIDE_GFX_VERSION=11.0.0"
        "PATH=${lib.makeBinPath [ pkgs.wtype pkgs.wl-clipboard ]}:/run/current-system/sw/bin"
      ];
      ExecSearchPath = [
        "${pkgs.wtype}/bin"
        "${pkgs.wl-clipboard}/bin"
      ];
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
