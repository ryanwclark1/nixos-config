{
  pkgs,
  ...
}:

{
  services.mako = {
    enable = true;

    # Position and layout
    anchor = "top-right";
    width = 420;
    height = 150;
    margin = "20";
    padding = "10,15";
    borderSize = 2;
    borderRadius = 8;

    # Typography
    font = "sans-serif 14";

    # Icons
    maxIconSize = 32;
    iconPath = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";

    # Timing
    defaultTimeout = 5000; # 5 seconds
    ignoreTimeout = false;

    # Layers
    layer = "overlay";

    # Behavior
    sort = "-time";
    maxVisible = 5;

    # Catppuccin Mocha theme colors
    backgroundColor = "#24273a";
    textColor = "#cad3f5";
    borderColor = "#c6d0f5";
    progressColor = "over #313244";

    # Urgency-specific colors
    extraConfig = ''
      [urgency=low]
      border-color=#a6da95
      default-timeout=3000

      [urgency=normal]
      border-color=#8aadf4
      default-timeout=5000

      [urgency=critical]
      border-color=#ed8796
      default-timeout=0

      [mode=do-not-disturb]
      invisible=1

      [mode=do-not-disturb urgency=critical]
      invisible=0

      [app-name=Spotify]
      invisible=1
    '';
  };

  # Add mako package
  home.packages = with pkgs; [
    mako
    libnotify # For notify-send testing
  ];
}
