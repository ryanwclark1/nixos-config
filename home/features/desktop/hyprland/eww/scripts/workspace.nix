{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/appname.sh" = {
    text = ''
      #!/usr/bin/env bash
      #define icons for workspaces 1-9
      ic=(0         )

      #initial check for occupied workspaces
      for num in $(hyprctl workspaces | grep " ID" | awk '{print $3}'); do
        export o"$num"="$num"
      done

      #initial check for focused workspace
      for num in $(hyprctl monitors | grep -B 5 "focused: yes" | awk 'NR==1{print $3}'); do
        export f"$num"="$num"
        export fnum=f"$num"
        export mon=$(hyprctl monitors | grep -B 6 "\($num\)" | awk 'NR==1{print $2}')
      done

      workspaces() {
      if [[ ${1:0:10} == "workspace>" ]] && [[ ${1:11} != "special" ]]; then #set focused workspace
        unset -v "$fnum"
        num=${1:11}
        export f"$num"="$num"
        export fnum=f"$num"

      elif [[ ${1:0:11} == "focusedmon>" ]]; then #set focused workspace following monitor focus change
        unset -v "$fnum"
        string=${1:12}
        num=${string##*,}
        export mon=${string/,*/}
        export f"$num"="$num"
        export fnum=f"$num"

      elif [[ ${1:0:14} == "moveworkspace>" ]] && [[ ${1##*,} == "$mon" ]]; then #Set focused workspace following swapactiveworkspace
        unset -v "$fnum"
        string=${1:15}
        num=${string/,*/}
        export f"$num"="$num"
        export fnum=f"$num"

      elif [[ ${1:0:16} == "createworkspace>" ]]; then #set Occupied workspace
        num=${1:17}
        export o"$num"="$num"
        export onum=o"$num"

      elif [[ ${1:0:17} == "destroyworkspace>" ]]; then #unset unoccupied workspace
        num=${1:18}
        unset -v o"$num"
      fi
      }
      module() {
      #output eww widget
      echo 	"(eventbox :onscroll \"echo {} | sed -e 's/up/-1/g' -e 's/down/+1/g' | xargs hyprctl dispatch workspace\" \
                (box	:class \"works\"	:orientation \"h\" :spacing 5 :space-evenly \"false\" :valign \"center\"	\
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 1\'\" :onrightclick \"hyprctl dispatch workspace 1 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o1$f1\" \"${ic[1]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 2\'\" :onrightclick \"hyprctl dispatch workspace 2 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o2$f2\" \"${ic[2]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 3\'\" :onrightclick \"hyprctl dispatch workspace 3 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o3$f3\" \"${ic[3]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 4\'\" :onrightclick \"hyprctl dispatch workspace 4 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o4$f4\" \"${ic[4]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 5\'\" :onrightclick \"hyprctl dispatch workspace 5 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o5$f5\" \"${ic[5]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 6\'\" :onrightclick \"hyprctl dispatch workspace 6 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o6$f6\" \"${ic[6]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 7\'\" :onrightclick \"hyprctl dispatch workspace 7 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o7$f7\" \"${ic[7]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 8\'\" :onrightclick \"hyprctl dispatch workspace 8 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o8$f8\" \"${ic[8]}\") \
                    (button :onclick \"hyprctl dispatch exec \'~/.config/hypr/themes/cyber/scripts/workspace 9\'\" :onrightclick \"hyprctl dispatch workspace 9 && $HOME/.config/hypr/themes/cyber/scripts/default_app\" :class \"0$o9$f9\" \"${ic[9]}\") \
                )\
              )"
      }

      module

      socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock - | while read -r event; do
      workspaces "$event"
      module
      done
		'';
		executable = true;
	};
}