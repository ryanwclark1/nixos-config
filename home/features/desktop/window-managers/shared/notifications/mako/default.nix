{
  pkgs,
  ...
}:

{
  # Omarchy-aligned Mako configuration
  # - Provides a shared core at ~/.local/share/omarchy/default/mako/core.ini
  # - Sets the active theme via ~/.config/omarchy/current/theme/mako.ini
  # - Points Mako to load the theme through ~/.config/mako/config

  #   # Catppuccin Mocha theme colors
  #   backgroundColor = "#24273a";
  #   textColor = "#cad3f5";
  #   borderColor = "#c6d0f5";
  #   progressColor = "over #313244";

  #   # Urgency-specific colors
  #   extraConfig = ''
  #     [urgency=low]
  #     border-color=#a6da95
  #     default-timeout=3000

  #     [urgency=normal]
  #     border-color=#8aadf4
  #     default-timeout=5000

  #     [urgency=critical]
  #     border-color=#ed8796
  #     default-timeout=0

  #     [mode=do-not-disturb]
  #     invisible=1

  #     [mode=do-not-disturb urgency=critical]
  #     invisible=0

  #     [app-name=Spotify]
  #     invisible=1
  #   '';
  # };

  # Add mako package
  home.packages = with pkgs; [
    mako
    libnotify # For notify-send testing
  ];

  # Ship Omarchy core for Mako (shared defaults, theme adds colors)
  home.file.".local/share/omarchy/default/mako/core.ini" = {
    force = true;
    text = ''
      # Position and layout
      anchor=top-right
      width=420
      height=150
      margin=20
      padding=10,15
      border-size=2
      border-radius=8

      # Typography
      font=sans-serif 14

      # Icons
      max-icon-size=32
      icon-path=${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark

      # Timing
      default-timeout=5000
      ignore-timeout=0

      # Layers
      layer=overlay

      # Behavior
      sort=-time
      max-visible=5
      history=1
      markup=1
      # format shows summary bold + body
      format=<b>%s</b>\n%b

      # Urgency-specific settings
      [urgency=low]
      default-timeout=3000

      [urgency=normal]
      default-timeout=5000

      [urgency=critical]
      default-timeout=0

      # Do-not-disturb mode integration (used by keybindings)
      [mode=do-not-disturb]
      invisible=1

      [mode=do-not-disturb urgency=critical]
      invisible=0
    '';
  };

  # Set active Omarchy theme for Mako (Catppuccin, matching other components)
  home.file.".config/omarchy/current/theme/mako.ini" = {
    force = true;
    text = ''
      include=~/.local/share/omarchy/default/mako/core.ini

      text-color=#cad3f5
      border-color=#c6d0f5
      background-color=#24273a
    '';
  };

  # Point Mako to load the Omarchy theme
  home.file.".config/mako/config" = {
    force = true;
    text = ''
      include=~/.config/omarchy/current/theme/mako.ini
    '';
  };
}
