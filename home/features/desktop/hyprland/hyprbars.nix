{
  config,
  inputs,
  pkgs,
  lib,
  outputs,
  ...
}:
# let
#   getHostname = x: lib.last (lib.splitString "@" x);
#   remoteColorschemes = lib.mapAttrs' (n: v: {
#   name = getHostname n;
#   value = v.config.colorscheme.rawColorscheme.colors.${config.colorscheme.mode};
#   }) outputs.homeConfigurations;
#   rgb = color: "rgb(${lib.removePrefix "#" color})";
#   rgba = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";
# in
{
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.hyprlandPlugins.hyprbars
      ];
    settings = {
      "plugin:hyprbars" = {
        bar_height = 20;
        # bar_color = rgba config.colorscheme.colors.surface "dd";
        # "col.text" = rgb config.colorscheme.colors.primary;
        # bar_text_font = config.fontProfiles.regular.family;
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
        #   "rgb(255,87,51),12,,${closeAction}"
        #   # Yellow "minimize" (send to special workspace) button
        #   "rgb(255,195,0),12,,${minimizeAction}"
        #   # Green "maximize" (fullscreen) button
        #   "rgb(218,247,166),12,,${maximizeAction}"
        # ];
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