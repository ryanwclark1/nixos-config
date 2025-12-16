{
  ...
}:

{
  imports = [ ./style.css.nix ];

  services.swaync = {
    enable = true;
    settings = {
      ### Popup positioning (notifications)
      positionX = "right";
      positionY = "top";

      notification-window-width = 360;
      notification-margin-top = 12;
      notification-margin-right = 12;
      notification-margin-left = 0;
      notification-margin-bottom = 0;

      notification-icon-size = 48;
      notification-inline-replies = true;

      timeout = 10;
      timeout-low = 5;
      timeout-critical = 30;

      ### Control Center geometry
      control-center-width = 360;
      control-center-height = -1;

      control-center-margin-top = 12;
      control-center-margin-right = 12;
      control-center-margin-bottom = 12;
      control-center-margin-left = 12;

      ### Hyprland-friendly layer-shell setup
      layer-shell = true;
      layer = "top";
      control-center-layer = "top";
      fit-to-screen = true;

      ### Behavior
      transition-time = 200;
      hide-on-clear = true;
      hide-on-action = true;
      keyboard-shortcuts = true;
      script-fail-notify = true;

      image-visibility = "always";

      ### Widgets
      widgets = [
        "title"
        "dnd"
        "buttons-grid"
        "mpris"
        "volume"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };

        dnd = {
          text = "Do Not Disturb";
        };

        mpris = {
          autohide = true;
        };

        volume = {
          label = "󰕾 ";
          show-per-app = true;
          show-per-app-icon = true;
          show-per-app-label = true;
          empty-list-label = "No active audio";
          expand-button-label = "⇧";
          collapse-button-label = "⇩";
          icon-size = 24;
          animation-type = "slide_down";
          animation-duration = 250;
        };

        buttons-grid = {
          actions = [
            { label = ""; command = "hyprlock"; }
            { label = "󰝟"; command = "pactl set-sink-mute @DEFAULT_SINK@ toggle"; }
            { label = "󰂯"; command = "blueman-manager"; }
            { label = ""; command = "wlogout"; }
          ];
        };
      };
    };
  };
}
