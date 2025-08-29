{
  config,
  lib,
  pkgs,
  ...
}:

let
  caps-lock-osd = pkgs.writeShellScript "caps-lock-osd" ''
    #!/usr/bin/env bash

    # SwayOSD Caps Lock indicator with proper state detection
    # This script detects the actual caps lock state and shows appropriate OSD

    if ! command -v swayosd-client >/dev/null; then
        exit 0  # SwayOSD not available
    fi

    # Method 1: Check via xset (if available)
    if command -v xset >/dev/null; then
        if xset q | grep -q "Caps Lock:.*off"; then
            # Caps lock is OFF, show it's being turned ON
            swayosd-client --caps-lock
        else
            # Caps lock is ON, show it's being turned OFF
            swayosd-client --caps-lock
        fi
        exit 0
    fi

    # Method 2: Check via /sys/class/leds (Linux specific)
    CAPS_LED_PATH="/sys/class/leds"
    CAPS_LED_FILE=$(find "$CAPS_LED_PATH" -name "*capslock*" -o -name "*caps*" 2>/dev/null | head -n1)

    if [[ -n "$CAPS_LED_FILE" && -r "$CAPS_LED_FILE/brightness" ]]; then
        # Read LED brightness (1 = on, 0 = off)
        if [[ "$(cat "$CAPS_LED_FILE/brightness" 2>/dev/null)" == "1" ]]; then
            # Caps lock LED is on, show OSD
            swayosd-client --caps-lock
        else
            # Caps lock LED is off, show OSD
            swayosd-client --caps-lock
        fi
        exit 0
    fi

    # Method 3: Fallback - just show the OSD (SwayOSD will figure it out)
    swayosd-client --caps-lock
  '';

  keybindings-script = pkgs.writeShellScript "hyprland-keybindings" ''
    #!/usr/bin/env bash

    # Get and process keybindings with auto-generated descriptions
    organized_keybinds=$(hyprctl binds -j | ${pkgs.jq}/bin/jq -r '
      def clean_nix_path: gsub("/nix/store/[^/]+/bin/"; "");
      
      def autogenerate_comment(dispatcher; params):
        if dispatcher == "killactive" then "Close window"
        elif dispatcher == "togglefloating" then "Float/unfloat window"
        elif dispatcher == "fullscreen" then
          if params == "0" then "Toggle fullscreen"
          elif params == "1" then "Toggle maximization" 
          else "Toggle fullscreen" end
        elif dispatcher == "movefocus" then
          if params == "l" then "Focus window left"
          elif params == "r" then "Focus window right"
          elif params == "u" then "Focus window up"
          elif params == "d" then "Focus window down"
          else "Move focus " + params end
        elif dispatcher == "movewindow" then
          if params == "l" then "Move window left"
          elif params == "r" then "Move window right" 
          elif params == "u" then "Move window up"
          elif params == "d" then "Move window down"
          else "Move window " + params end
        elif dispatcher == "resizeactive" then "Resize window by " + params
        elif dispatcher == "splitratio" then "Window split ratio " + params
        elif dispatcher == "workspace" then
          if params == "e+1" then "Next workspace"
          elif params == "e-1" then "Previous workspace"
          elif params == "previous" then "Previous workspace"
          else "Go to workspace " + params end
        elif dispatcher == "movetoworkspace" then
          if params == "e+1" then "Move window to next workspace"
          elif params == "e-1" then "Move window to previous workspace" 
          else "Move window to workspace " + params end
        elif dispatcher == "togglespecialworkspace" then "Toggle special workspace"
        elif dispatcher == "swapsplit" then "Swap window split"
        elif dispatcher == "pseudo" then "Toggle pseudo tiling"
        elif dispatcher == "togglegroup" then "Toggle window group"
        elif dispatcher == "lockactivegroup" then "Lock/unlock active group"
        elif dispatcher == "exec" then
          if (params | test("rofi.*drun")) then "App launcher"
          elif (params | test("rofi.*show calc")) then "Calculator"
          elif (params | test("rofi.*emoji")) then "Emoji picker"
          elif (params | test("cliphist")) then "Clipboard history"
          elif (params | test("screenshot")) then "Screenshot menu"
          elif (params | test("powermenu")) then "Power menu"
          elif (params | test("keybindings")) then "Show keybindings"
          elif (params | test("web-search")) then "Web search"
          elif (params | test("kitty")) then "Open terminal"
          elif (params | test("google-chrome|chrome")) then "Open browser"
          elif (params | test("code")) then "Open VS Code"
          elif (params | test("nautilus")) then "Open file manager"
          elif (params | test("hyprlock")) then "Lock screen"
          elif (params | test("wlogout")) then "Logout menu"
          elif (params | test("swayosd-client.*volume")) then "Volume control"
          elif (params | test("swayosd-client.*brightness")) then "Brightness control"
          elif (params | test("playerctl")) then "Media control"
          elif (params | test("waybar")) then "Restart status bar"
          elif (params | test("hyprctl reload")) then "Reload Hyprland config"
          else "Execute: " + (params | clean_nix_path) end
        else dispatcher + " " + params
        end;
      
      def get_category(dispatcher; params):
        if dispatcher == "exec" then
          if (params | test("rofi|dmenu|cliphist|emoji|calc|web-search")) then "🔍 Menus & Search"
          elif (params | test("kitty|terminal")) then "💻 Terminal"
          elif (params | test("chrome|firefox|browser")) then "🌐 Browser"  
          elif (params | test("code|cursor|editor")) then "📝 Editor"
          elif (params | test("screenshot|grimblast")) then "📸 Screenshot"
          elif (params | test("swayosd-client|playerctl|wpctl")) then "🔊 Media & Volume"
          elif (params | test("brightnessctl")) then "🔆 Brightness"
          elif (params | test("hyprlock|wlogout|powermenu")) then "🔐 System Control"
          elif (params | test("nautilus|file")) then "📁 File Manager"
          elif (params | test("waybar|hyprctl")) then "⚙️ System Management"
          else "🚀 Applications" end
        elif dispatcher == "killactive" then "❌ Window Control"
        elif (dispatcher | test("movewindow|resizeactive|movefocus|swapsplit|splitratio")) then "🪟 Window Management"
        elif (dispatcher | test("togglefloating|fullscreen|pseudo|togglegroup|lockactivegroup")) then "🪟 Window Management" 
        elif (dispatcher | test("workspace|movetoworkspace|togglespecialworkspace")) then "🏠 Workspaces"
        else "⚙️ System Management"
        end;
      
      .[] | 
      {
        dispatcher: .dispatcher,
        arg: .arg,
        key: .key,
        modmask: .modmask,
        combo: (if .modmask == 64 then "SUPER"
               elif .modmask == 8 then "ALT"
               elif .modmask == 4 then "CTRL" 
               elif .modmask == 1 then "SHIFT"
               elif .modmask == 72 then "SUPER + ALT"
               elif .modmask == 68 then "SUPER + CTRL"
               elif .modmask == 65 then "SUPER + SHIFT"
               elif .modmask == 12 then "CTRL + ALT"
               elif .modmask == 9 then "SHIFT + ALT"
               elif .modmask == 5 then "SHIFT + CTRL"
               else (.modmask | tostring)
               end) + " + " + .key,
        description: autogenerate_comment(.dispatcher; .arg),
        category: get_category(.dispatcher; .arg)
      } | select(.description != "") |
      .combo + "\t" + .description + "\t" + .category
    ' | sort -k3,3 -k1,1 | awk -F'\t' '
      BEGIN { current_category = "" }
      {
        if ($3 != current_category) {
          if (current_category != "") print ""
          print "--- " $3 " ---"
          current_category = $3
        }
        print $1 "\r" $2
      }
    ')

    if [ -z "$organized_keybinds" ]; then
        echo "No keybindings found or hyprctl not available"
        exit 1
    fi

    ${pkgs.rofi-wayland}/bin/rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" <<< "$organized_keybinds"
  '';
in

{
  wayland.windowManager.hyprland.settings = {
    # Mouse bindings
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    bind = lib.flatten [
      # Window management
      [
        "SUPER, Q, killactive"
        "ALT, F4, killactive"
        "SUPER SHIFT, Q, exec, hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"
        "SUPER SHIFT, E, exit"
        "SUPER SHIFT, SPACE, togglefloating"
        "SUPER, F, fullscreen, 1"
        "SUPER SHIFT, F, fullscreen, 0"
        "SUPER, M, fullscreen, 0"
        "SUPER, P, togglesplit"
        "SUPER, G, togglegroup"
        "SUPER, T, lockactivegroup, toggle"
        "SUPER, I, pseudo"
        "SUPER, K, swapsplit"
      ]

      # Window sizing
      [
        "SUPER, minus, splitratio, -0.1"
        "SUPER, equal, splitratio, 0.1"
        "SUPER SHIFT, minus, splitratio, -0.2"
        "SUPER SHIFT, equal, splitratio, 0.2"
      ]

      # Workspace navigation
      [
        "SUPER, Tab, workspace, e+1"
        "SUPER SHIFT, Tab, workspace, e-1"
        "SUPER, apostrophe, workspace, previous"
        "SUPER, left, workspace, e-1"
        "SUPER, right, workspace, e+1"
        "SUPER, mouse_down, workspace, e+1"
        "SUPER, mouse_up, workspace, e-1"
      ]

      # Move window to workspace
      [
        "SUPER SHIFT, left, movetoworkspace, e-1"
        "SUPER SHIFT, right, movetoworkspace, e+1"
      ]

      # Special workspace
      [
        "SUPER, U, togglespecialworkspace, scratchpad"
        "SUPER SHIFT, U, movetoworkspace, special:scratchpad"
      ]

      # Applications
      [
        "SUPER, Return, exec, kitty"
        "SUPER, E, exec, code"
        "SUPER, B, exec, google-chrome-stable"
        "SUPER, N, exec, nautilus"
        "SUPER ALT, SPACE, exec, nautilus"
      ]

      # Utility applications (conditional on availability)
      [
        "SUPER CTRL, E, exec, pkill rofi || rofi -modi emoji -show emoji"
        "SUPER CTRL, C, exec, pkill rofi || rofi -show calc -modi calc -no-show-match -no-sort"
      ]

      # Rofi menus
      (lib.optionals config.programs.rofi.enable [
        "SUPER, SPACE, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-center.rasi"
        "SUPER, X, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-center.rasi"
        "SUPER, Z, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-full.rasi"
        "SUPER SHIFT, W, exec, web-search"
        "SUPER, V, exec, cliphist list | rofi -dmenu -theme ${config.home.homeDirectory}/.config/rofi/style/cliphist.rasi | cliphist decode | wl-copy"
      ])

      # Screenshot
      [
        ", Print, exec, ${config.home.homeDirectory}/.config/hypr/scripts/rofi/screenshot-menu.sh"
        "SUPER, S, exec, ${config.home.homeDirectory}/.config/hypr/scripts/rofi/screenshot-menu.sh"
        "SUPER SHIFT, S, exec, ${config.home.homeDirectory}/.config/hypr/scripts/rofi/screenshot-menu.sh"
      ]

      # Power menu
      [
        "SUPER, Escape, exec, ${config.home.homeDirectory}/.config/hypr/scripts/rofi/powermenu-unified.sh"
        "SUPER, BackSpace, exec, wlogout"
      ]

      # Movement (vim keys)
      (let
        mvfocus = dir: "SUPER, ${dir}, movefocus, ${dir}";
        mvwindow = dir: "SUPER SHIFT, ${dir}, movewindow, ${dir}";
        resizeactive = (dir: amount: "SUPER CTRL, ${dir}, resizeactive, ${amount}");
      in [
        (mvfocus "H") (mvfocus "L") (mvfocus "K") (mvfocus "J")
        (mvfocus "left") (mvfocus "right") (mvfocus "up") (mvfocus "down")
        (mvwindow "H") (mvwindow "L") (mvwindow "K") (mvwindow "J")
        (mvwindow "left") (mvwindow "right") (mvwindow "up") (mvwindow "down")
        (resizeactive "H" "-20 0") (resizeactive "L" "20 0")
        (resizeactive "K" "0 -20") (resizeactive "J" "0 20")
        (resizeactive "left" "-20 0") (resizeactive "right" "20 0")
        (resizeactive "up" "0 -20") (resizeactive "down" "0 20")
      ])

      # Workspace switching (numbers 1-10)
      (builtins.concatLists (builtins.genList (
        i: let
          ws = toString (i + 1);
          key = if i == 9 then "0" else ws;
        in [
          "SUPER, ${key}, workspace, ${ws}"
          "SUPER SHIFT, ${key}, movetoworkspace, ${ws}"
        ]
      ) 10))

      # Workspace switching (numpad)
      (builtins.concatLists (builtins.genList (
        i: let
          ws = toString (i + 1);
        in [
          "SUPER, KP_${ws}, workspace, ${ws}"
          "SUPER SHIFT, KP_${ws}, movetoworkspace, ${ws}"
        ]
      ) 10))

      # System management
      [
        "SUPER CTRL, R, exec, hyprctl reload"
        "SUPER CTRL, B, exec, pkill waybar; sleep 0.5; waybar &"
        "SUPER CTRL, L, exec, hyprlock"
      ]

      # Function keys
      [
        "SUPER, F1, exec, ${keybindings-script}"
        "SUPER CTRL, K, exec, ${keybindings-script}"
      ]

      # Media keys
      (lib.optionals config.services.playerctld.enable [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioStop, exec, playerctl stop"
        "SHIFT, XF86AudioNext, exec, playerctld shift"
        "SHIFT, XF86AudioPrev, exec, playerctld unshift"
        "SHIFT, XF86AudioPlay, exec, systemctl --user restart playerctld"
      ])

      # Volume control (SwayOSD with fallbacks)
      [
        ", XF86AudioRaiseVolume, exec, command -v swayosd-client >/dev/null && swayosd-client --output-volume raise || (wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+)"
        ", XF86AudioLowerVolume, exec, command -v swayosd-client >/dev/null && swayosd-client --output-volume lower || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, command -v swayosd-client >/dev/null && swayosd-client --output-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "SHIFT, XF86AudioRaiseVolume, exec, command -v swayosd-client >/dev/null && swayosd-client --input-volume raise || wpctl set-volume -l 1 @DEFAULT_AUDIO_SOURCE@ 5%+"
        "SHIFT, XF86AudioLowerVolume, exec, command -v swayosd-client >/dev/null && swayosd-client --input-volume lower || wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"
        "SHIFT, XF86AudioMute, exec, command -v swayosd-client >/dev/null && swayosd-client --input-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioMicMute, exec, command -v swayosd-client >/dev/null && swayosd-client --input-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ]

      # Brightness control (SwayOSD with fallbacks)
      [
        ", XF86MonBrightnessUp, exec, command -v swayosd-client >/dev/null && swayosd-client --brightness raise || brightnessctl -q set +10%"
        ", XF86MonBrightnessDown, exec, command -v swayosd-client >/dev/null && swayosd-client --brightness lower || brightnessctl -q set 10%-"
      ]

      # Hardware keys
      [
        ", XF86Calculator, exec, pkill rofi || rofi -show calc -modi calc -no-show-match -no-sort"
        ", XF86Lock, exec, hyprlock"
      ]

      # SwayOSD additional bindings
      [
        ", Caps_Lock, exec, ${caps-lock-osd}"
      ]

      # Plugin bindings
      [
        "SUPER ALT, grave, hyprexpo:expo, toggle"
      ]
    ];
  };
}
