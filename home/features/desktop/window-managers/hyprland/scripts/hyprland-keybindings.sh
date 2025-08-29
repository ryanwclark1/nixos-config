#!/usr/bin/env bash

# Hyprland keybindings display with auto-generated descriptions
# Dependencies: hyprctl, jq, rofi-wayland

# Check for required dependencies
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found. Make sure Hyprland is installed and running." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not found. Please install jq package." >&2
    exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "Error: rofi not found. Please install rofi-wayland package." >&2
    exit 1
fi

# Get and process keybindings with auto-generated descriptions
organized_keybinds=$(hyprctl binds -j | jq -r '
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
' 2>/dev/null | sort -k3,3 -k1,1 | awk -F'\t' '
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

# Check if we got any keybindings
if [ -z "$organized_keybinds" ]; then
    echo "Error: No keybindings found or hyprctl failed to get bindings." >&2
    exit 1
fi

# Display in rofi
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" <<< "$organized_keybinds"