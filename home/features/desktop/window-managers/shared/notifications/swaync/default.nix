{
  ...
}:



{
  imports = [ ./style.css.nix ];

  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";

      control-center-positionX = "none";
      control-center-positionY = "none";
      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      control-center-margin-left = 8;
      control-center-width = 500;
      control-center-height = -1;

      fit-to-screen = false;

      layer-shell-cover-screen = true;
      layer-shell = true;
      layer = "overlay";

      control-center-layer = "overlay";

      cssPriority = "application";

      notification-body-image-height = 100;
      notification-body-image-width = 200;
      notification-inline-replies = true;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "always";

      transition-time = 200;
      hide-on-clear = true;
      hide-on-action = true;
      script-fail-notify = true;

      notification-2fa-action = true;

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
        "notifications": {
          "vexpand": false
        },
        inhibitors = {
          text = "Inhibitors";
          clear-all-button = true;
          button-text = "Clear All";
        };
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 5;
          text = "Lavel Text";
        };
        mpris = {
          autohide = true
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
      };
    };
  };
}
