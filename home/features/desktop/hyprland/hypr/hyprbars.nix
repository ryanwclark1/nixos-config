{
  config,
  pkgs,
  lib,
  ...
}:

# TODO: Figure out toggle
# Option1: hyprctl -j getoption plugin:hyprbars:bar_height | jq -re '.int != 0' (Can't find)
# Option2: hyprctl unload plugin:hyprbars (Can't find)

{
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.hyprlandPlugins.hyprbars
      ];
    settings = {
      "plugin:hyprbars" = {
        bar_height = 0;
        # bar_color = "rgba(${base07}50)";
        # "col.text" = "rgba(${base01}75)";
        bar_text_font = "UbuntuMono Nerd Font";
        bar_text_size = 11;
        bar_part_of_window = true;
        bar_precedence_over_border = true;

        # hyprbars-button =
        # let
        #   closeAction = "hyprctl dispatch killactive";
        #   isOnSpecial = ''hyprctl activewindow -j | jq -re 'select(.workspace.name == "special")' >/dev/null'';
        #   moveToSpecial = "hyprctl dispatch movetoworkspacesilent special";
        #   moveToActive = "hyprctl dispatch movetoworkspacesilent name:$(hyprctl -j activeworkspace | jq -re '.name')";
        #   minimizeAction = "${isOnSpecial} && ${moveToActive} || ${moveToSpecial}";
        #   maximizeAction = "hyprctl dispatch fullscreen 1";
        # in [
        #   # Red close button
        #   "rgb(${base08}),12,,${closeAction}"
        # #   # Yellow "minimize" (send to special workspace) button
        #   "rgb(${base0A}),12,,${minimizeAction}"
        # #   # Green "maximize" (fullscreen) button
        #   "rgb(${base0B}),12,,${maximizeAction}"
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
