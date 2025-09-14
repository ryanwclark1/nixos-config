{
  ...
}:

{
  # Enable UPower for desktop systems to prevent D-Bus activation errors
  # Even though desktops don't have batteries, some applications still query UPower
  services.upower = {
    enable = true;
  };
}