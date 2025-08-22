{
  ...
}:

{
  # SwayOSD configuration
  # Note: SwayOSD automatically detects displays, no --display option needed
  
  services.swayosd = {
    enable = true;
    # stylePath can be set if you want custom CSS styling
    # stylePath = "${config.home.homeDirectory}/.config/swayosd/style.css";
  };
}
