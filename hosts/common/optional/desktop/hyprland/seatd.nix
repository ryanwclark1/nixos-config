{
  lib,
  pkgs,
  ...
}:

{
  # Enable seatd for proper seat management with Hyprland
  services.seatd = {
    enable = true;
    group = "seat";
  };

  # Override systemd service to prevent the notify/activation timeout loop
  systemd.services.seatd = {
    serviceConfig = {
      Type = lib.mkForce "simple";
      ExecStart = lib.mkForce "${pkgs.seatd}/bin/seatd -u root -g seat -l info";
    };
  };

  # Add users to the seat group for Hyprland
  users.groups.seat = {};
}
