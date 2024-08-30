{
  lib,
  ...
}:

{
  wayland.windowManager.hyprland.settings = {
    bindm = [
      "SUPER,mouse:272,movewindow"
      "SUPER,mouse:273,resizewindow"
    ];

    bind = let
      workspaces = [
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      ];
      # Map keys (arrows and hjkl) to hyprland directions (l, r, u, d)
      directions = rec {
          left = "l";
          right = "r";
          up = "u";
          down = "d";
          h = left;
          l = right;
          k = up;
          j = down;
      };
    in
      [
        "SUPER SHIFT,q,killactive"
        "SUPER SHIFT,e,exit"

        # "SUPER,s,togglesplit"
        "SUPER,f,fullscreen,1"
        "SUPER SHIFT,f,fullscreen,0"
        "SUPER SHIFT,space,togglefloating"

        "SUPER,minus,splitratio,-0.25"
        "SUPER SHIFT,minus,splitratio,-0.3333333"

        "SUPER,equal,splitratio,0.25"
        "SUPER SHIFT,equal,splitratio,0.3333333"

        "SUPER,g,togglegroup"
        "SUPER,t,lockactivegroup,toggle"
        "SUPER,tab,changegroupactive,f"
        "SUPER SHIFT,tab,changegroupactive,b"

        "SUPER,apostrophe,workspace,previous"
        "SUPER SHIFT,apostrophe,workspace,next"

        "SUPER,u,togglespecialworkspace"
        "SUPER SHIFT,u,movetoworkspacesilent,special"
        "SUPER,i,pseudo"
      ]
      ++
      # Change workspace
      (map (n: "SUPER,${n},workspace,name:${n}") workspaces)
      ++
      # Move window to workspace
      (map (n: "SUPER SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
      ++
      # Move focus
      (lib.mapAttrsToList (key: direction: "SUPER,${key},movefocus,${direction}") directions)
      ++
      # Swap windows
      (lib.mapAttrsToList (key: direction: "SUPER SHIFT,${key},swapwindow,${direction}") directions)
      ++
      # Move windows
      (lib.mapAttrsToList (key: direction: "SUPER CONTROL,${key},movewindoworgroup,${direction}") directions)
      ++
      # Move monitor focus
      (lib.mapAttrsToList (key: direction: "SUPER ALT,${key},focusmonitor,${direction}") directions)
      ++
      # Move workspace to other monitor
      (lib.mapAttrsToList (key: direction: "SUPER ALT SHIFT,${key},movecurrentworkspacetomonitor,${direction}") directions);
  };
}