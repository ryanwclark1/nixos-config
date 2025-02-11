{
  ...
}:



{
  # home.file.".config/swaync/config.json" = {
  #   source = ./config.json;
  # };

  home.file.".config/swaync.style.css" = {
    source = ./style.css;
  };

  services.swaync = {
    enable = true;
    settings = ''
      "positionX": "right",
      "positionY": "top",
      "layer": "overlay",
      "control-center-layer": "top",
      "layer-shell": true,
      "cssPriority": "user",
      "control-center-margin-top": 13,
      "control-center-margin-bottom": 0,
      "control-center-margin-right": 14,
      "control-center-margin-left": 0,
      "notification-2fa-action": true,
      "notification-inline-replies": false,
      "notification-icon-size": 24,
      "notification-body-image-height": 100,
      "notification-body-image-width": 100,
      "notification-window-width": 300,
      "timeout": 6,
      "timeout-low": 3,
      "timeout-critical": 0,
      "fit-to-screen": false,
      "control-center-width": 400,
      "control-center-height": 720,
      "keyboard-shortcuts": true,
      "image-visibility": "when available",
      "transition-time": 200,
      "hide-on-clear": false,
      "hide-on-action": true,
      "script-fail-notify": true,
      "widgets": [
        "dnd",
        "buttons-grid",
        "mpris",
        "volume",
        "backlight",
        "title",
        "notifications"
      ],
      "widget-config": {
        "title": {
          "text": "Notifications",
          "clear-all-button": true,
          "button-text": "Clear"
        },
        "dnd": {
          "text": "Do Not Disturb"
        },
        "label": {
          "max-lines": 1,
          "text": "Notification"
        },
        "mpris": {
          "image-size": 50,
          "image-radius": 0
        },
        "volume": {
          "label": "󰕾"
        },
        "backlight": {
          "label": "󰃟"
        },
        "buttons-grid": {
          "actions": [
            {
              "label": "",
              "command": "hyprlock"
            },
            {
              "label": "󰝟",
              "command": "pactl set-sink-mute @DEFAULT_SINK@ toggle"
            },
            {
              "label": "󰂯",
              "command": "blueman-manager"
            },
            {
              "label": "",
              "command": "bash -c $HOME/.config/ml4w/scripts/wlogout.sh"
            }
          ]
        }
      }
    '';
  };
}