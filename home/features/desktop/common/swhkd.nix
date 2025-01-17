{
  pkgs, envir, brightnesctrl, ...
}:
{
  services.swhkd = {
    enable = true;
    settings = let
      killactive = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch killactive"
        else if envir == "sway" then "swaymsg kill"
        else "";
      togglesplit = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch togglesplit"
        else if envir == "sway" then "swaymsg layout toggle split"
        else "echo 'no envir'";
      togglefloating = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch togglefloating"
        else if envir == "sway" then "swaymsg floating toggle"
        else "";
      pseudo = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch pseudo"
        else if envir == "sway" then "swaymsg pseudo"
        else "";
      nextworkspace = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch workspace e+1"
        else if envir == "sway" then "swaymsg workspace next"
        else "";
      prevworkspace = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch workspace e-1"
        else if envir == "sway" then "swaymsg workspace prev"
        else "";
      movenextworkspace = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspace e+1"
        else if envir == "sway" then "swaymsg move container to workspace next"
        else "";
      moveprevworkspace = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspace e-1"
        else if envir == "sway" then "swaymsg move container to workspace prev"
        else "";
      fullscreen = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch fullscreen"
        else if envir == "sway" then "swaymsg fullscreen toggle"
        else "";
      nextactivewindow = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch cyclenext"
        else if envir == "sway" then "swaymsg focus next"
        else "";
      movetoworkspace = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspace"
        else if envir == "sway" then "swaymsg move container to workspace"
        else "";
      workspace = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch workspace"
        else if envir == "sway" then "swaymsg workspace"
        else "";
      movefocus = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch movefocus "
        else if envir == "sway" then "bash -c 'if [ \"$@\" == \"r\" ]; then swaymsg focus right; elif [ \"$@\" == \"l\" ]; then swaymsg focus left; elif [ \"$@\" == \"d\" ]; then swaymsg focus down; elif [ \"$@\" == \"u\" ]; then swaymsg focus up; fi' -- "
        else "";
      exit = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl dispatch exit"
        else if envir == "sway" then "swaymsg exit"
        else "";
      reload = if envir=="Hyprland" then "${pkgs.hyprland}/bin/hyprctl reload"
        else if envir == "sway" then "swaymsg reload"
        else "";
    in ''

super + shift + q
  ${killactive}

super + s
  ${togglesplit}

super + j
  ${togglefloating}

super + g
  ${fullscreen}

super + p
  ${pseudo}

super + m
  ${exit}

super + tab
  ${nextactivewindow}

ctrl + right
  ${nextworkspace}

ctrl + left
  ${prevworkspace}

super + {1-9, 0}
  ${workspace} {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

ctrl + shift + right
  ${movenextworkspace}

ctrl + shift + left
  ${moveprevworkspace}

ctrl + shift + {1-9, 0}
  ${movetoworkspace} {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

super + {right, left, down, up}
  ${movefocus} {r, l, d, u}

super + shift + t
  alacritty

super + shift + k
  kitty

super + shift + b
  firefox

super + shift + f
  nautilus

super + shift + p
  hyprpicker -a

super + shift + e
  eww-move

super + shift + n
  swaync-client -t

super + shift + z
  ${pkgs.killall}/bin/killall -SIGUSR1 gpu-screen-recorder && sleep 0.5 && notify-send -t 3500 -u low -- "GPU Screen Recorder" "Replay saved"

super + shift + r
  eww-launcher

super + shift + y
  eww reload

super + r
  anyrun

super + shift + c
  cliphist list | anyrun --show-results-immediately true | cliphist decode | wl-copy

super + shift + l
  hyprlock

super + shift + /
  ${reload}

super + shift + 3
  wayshot -s "$(slurp)" --stdout | swappy -f -

super + shift + 4
  wayshot -s "$(slurp)" -f $HOME/Pictures/Screenshots/shot_$(date '+%Y-%m-%d_%H:%M:%S').png

super + shift + 5
  wayshot -s "$(slurp)" --stdout | wl-copy

xf86monbrightnessdown
  ${brightnesctrl.down}
xf86monbrightnessup
  ${brightnesctrl.up}
xf86audioplay
  ${pkgs.playerctl}/bin/playerctl play-pause
xf86audioprev
  ${pkgs.playerctl}/bin/playerctl previous
xf86audionext
  ${pkgs.playerctl}/bin/playerctl next

# Remove pamixer and use pipewire utility instead
xf86audiolowervolume
  pamixer -d 10
xf86audioraisevolume
  pamixer -i 10
xf86audiomute
  pamixer -t
xf86audiomicmute
  pamixer --default-source -t
    '';
  };
}