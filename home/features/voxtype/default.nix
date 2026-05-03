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

  programs.voxtype = {
    enable = true;
    package = inputs.voxtype.packages.${system}.rocm;
    model.name = "medium.en";
    service.enable = true;
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
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      Environment = [
        "HSA_OVERRIDE_GFX_VERSION=11.0.0"
        "PATH=${lib.makeBinPath [ pkgs.wtype pkgs.wl-clipboard ]}:/run/current-system/sw/bin"
      ];
    };

    Install = lib.mkForce { };
  };
}
