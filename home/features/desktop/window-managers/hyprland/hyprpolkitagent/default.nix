{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  services.hyprpolkitagent = {
    enable = lib.mkDefault true;
    package = inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
  };
}
