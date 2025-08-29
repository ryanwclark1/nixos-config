{
  pkgs,
  ...
}:

{
  home.file.".config/wlogout/icons" = {
    source = ./icons;
    recursive = true;
  };

  home.file.".config/wlogout/style.css" = {
    source = ./style.css;
  };

  programs.wlogout = {
    enable = true;
    package = pkgs.wlogout;
    layout = [
      {
        label = "lock";
        action = "~/.config/hypr/scripts/system/power.sh lock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "~/.config/hypr/scripts/system/power.sh logout";
        text = "Exit";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "~/.config/hypr/scripts/system/power.sh suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "~/.config/hypr/scripts/system/power.sh reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "~/.config/hypr/scripts/system/power.sh shutdown";
        text = "Shutdown";
        keybind = "s";
      }

    ];
    # style = ''
    #   * {
    #     font-family: "JetBrainsMono Nerd Font", FontAwesome, sans-serif;
    #   	background-image: none;
    #   	transition: 20ms;
    #   }
    #   window {
    #   	background-color: rgba(12, 12, 12, 0.1);
    #   }
    #   button {
    #   	color: #${config.lib.stylix.optionswithHashtag.base05};
    #     font-size:20px;
    #     background-repeat: no-repeat;
    #   	background-position: center;
    #   	background-size: 25%;
    #   	border-style: solid;
    #   	background-color: rgba(12, 12, 12, 0.3);
    #   	border: 3px solid #${config.lib.stylix.colors.base05};
    #     box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
    #   }
    #   /* button:hover */
    #   button:focus,
    #   button:active {
    #     color: #${config.lib.stylix.colors.base0E};
    #     background-color: rgba(12, 12, 12, 0.5);
    #     border: 3px solid #${config.lib.stylix.colors.base0E};
    #   }
    #   #logout {
    #   	margin: 10px;
    #   	border-radius: 20px;
    #   	background-image: image(url("icons/logout.png"));
    #   }
    #   #suspend {
    #   	margin: 10px;
    #   	border-radius: 20px;
    #   	background-image: image(url("icons/suspend.png"));
    #   }
    #   #shutdown {
    #   	margin: 10px;
    #   	border-radius: 20px;
    #   	background-image: image(url("icons/shutdown.png"));
    #   }
    #   #reboot {
    #   	margin: 10px;
    #   	border-radius: 20px;
    #   	background-image: image(url("icons/reboot.png"));
    #   }
    #   #lock {
    #   	margin: 10px;
    #   	border-radius: 20px;
    #   	background-image: image(url("icons/lock.png"));
    #   }
    #   #hibernate {
    #   	margin: 10px;
    #   	border-radius: 20px;
    #   	background-image: image(url("icons/hibernate.png"));
    #   }
    # '';
  };
}