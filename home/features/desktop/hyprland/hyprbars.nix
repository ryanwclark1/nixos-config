{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    plugins = [
      # inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprbars
    ];
    settings = {
      "plugin:hyprbars" = {
        bar_height = 25;
        bar_text_size = 12;
        bar_part_of_window = true;
        hyprbars-button =
          let
            closeAction = "hyprctl dispatch killactive";
            isOnSpecial = ''hyprctl activewindow -j | jq -re 'select(.workspace.name == "special")' >/dev/null'';
            moveToSpecial = "hyprctl dispatch movetoworkspacesilent special";
            moveToActive = "hyprctl dispatch movetoworkspacesilent name:$(hyprctl -j activeworkspace | jq -re '.name')";
            minimizeAction = "${isOnSpecial} && ${moveToActive} || ${moveToSpecial}";
            maximizeAction = "hyprctl dispatch togglefloating";
          in
          [
            # Red close button
            "rgb(255, 87, 51),12,,${closeAction}"
            # Yellow "minimize" (send to special workspace) button
            "rgb(255, 195, 0),12,,${minimizeAction}"
            # Green "maximize" (togglefloating) button
            "rgb(218, 247, 166),12,,${maximizeAction}"
          ];
      };
      bind =
        let
          barsEnabled = "hyprctl -j getoption plugin:hyprbars:bar_height | ${lib.getExe pkgs.jq} -re '.int != 0'";
          setBarHeight = height: "hyprctl keyword plugin:hyprbars:bar_height ${toString height}";
          toggleOn = setBarHeight config.wayland.windowManager.hyprland.settings."plugin:hyprbars".bar_height;
          toggleOff = setBarHeight 0;
        in
        [
          "SUPER,m,exec,${barsEnabled} && ${toggleOff} || ${toggleOn}"
        ];
    };
  };
}
