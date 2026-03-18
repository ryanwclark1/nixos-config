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
      hotkey.enabled = false;
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

    Install = lib.mkForce { };
  };
}
