{
  ...
}:



{
  imports = [ ./style.css.nix ];

  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      layer = "overlay";
      layer-shell = true;
      layer-shell-cover-screen = true;
      cssPriority = "application";
      positionY = "top";
      control-center-positionX = "none";
      control-center-positionY = "none";
      control-center-margin-top = 13;
      control-center-margin-bottom = 0;
      control-center-margin-right = 14;
      control-center-margin-left = 0;
      control-center-layer = "top";
      control-center-exclusive-zone = true;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      notification-window-width = 500;
      fit-to-screen = false;
      relative-timestamps = true;
      control-center-height = 600;
      control-center-width = 400;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      text-empty = "No notifications";
      script-fail-notify = true;
      widgets = [
        "inhibitors"
        "dnd"
        "buttons-grid"
        "mpris"
        "volume"
        "title"
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
        label = {
          max-lines = 1;
          text = "Notification";
        };
        mpris = {
          image-size = 96;
        };
        volume = {
          label = "󰕾 ";
          show-per-app = true;
          show-per-app-icon = true;
          show-per-app-label = true;
          empty-list-label = "No active sink input";
          expand-button-lablel = "⇧";
          collapse-button-label = "⇩";
          icon-size = 24;
          animation-type = "slide_down";
          animation-duration = 250;
        };
        # backlight = {
        #   label = "󰃟 ";
        # };
        buttons-grid = {
          actions = [
            {
              label = " ";
              command = "hyprlock";
            }
            {
              label = "󰝟 ";
              command = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
            }
            {
              label = "󰂯";
              command = "blueman-manager";
            }
            {
              label = " ";
              command = "bash -c $HOME/.config/hypr/scripts/system/hypr-utils.sh wlogout";
            }
          ];
        };
        inhibitors = {
          text = "Inhibitors";
          clear-all-button = true;
          button-text = "Clear All";
        };
      };
    };
  };
}
