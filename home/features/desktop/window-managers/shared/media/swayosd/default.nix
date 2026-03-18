{
  lib,
  ...
}:

{
  # SwayOSD configuration
  # Note: SwayOSD automatically detects displays, no --display option needed

  services.swayosd = {
    enable = true;
    stylePath = ./style.css;
  };

  systemd.user.services.swayosd = {
    Unit = {
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Install = lib.mkForce { };
  };
}
