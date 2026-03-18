{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  services.hyprpolkitagent = {
    enable = true;
    package = inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Install = lib.mkForce { };
  };
}
