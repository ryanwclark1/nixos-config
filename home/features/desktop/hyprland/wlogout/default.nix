{
  pkgs,
  ...
}:

{
  programs.wlogout = {
    enable = true;
    package = pkgs.wlogout;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate  ";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "logout";
        action = "killall -9 Hyprland";
        text = "Exit";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend ";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];
    style = ''
      button {
        color: #FFFFFF;
        font-size:20px;

        background-repeat: no-repeat;
          background-position: center;
          background-size: 25%;

          border-style: solid;
          background-color: rgba(12, 12, 12, 0.3);
          border: 3px solid #FFFFFF;

        box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
        }

        button:focus,
        button:active,
        button:hover {
          color: @color11;
          background-color: rgba(12, 12, 12, 0.5);
          border: 3px solid @color11;
      }

      /*
      -----------------------------------------------------
      Buttons
      -----------------------------------------------------
      */

      #lock {
        margin: 10px;
        border-radius: 20px;
      }

      #logout {
        margin: 10px;
        border-radius: 20px;
      }

      #suspend {
        margin: 10px;
        border-radius: 20px;
      }

      #hibernate {
        margin: 10px;
        border-radius: 20px;
      }

      #shutdown {
        margin: 10px;
        border-radius: 20px;
      }

      #reboot {
        margin: 10px;
        border-radius: 20px;
      }
    '';
  };
}