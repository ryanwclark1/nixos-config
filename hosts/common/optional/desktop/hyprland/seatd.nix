{
  lib,
  ...
}:

{
  # Enable seatd for proper seat management with Hyprland
  services.seatd = {
    enable = true;
    group = "seat";
  };

  # Add users to the seat group for Hyprland
  users.groups.seat = {};
}
