#!/usr/bin/env bash

# System menu using walker - adapted from omarchy-menu for NixOS
#
# This menu system provides hierarchical navigation through system functions,
# inspired by Omarchy's comprehensive menu structure

# Set to true when going directly to a submenu, so we can exit directly
BACK_TO_EXIT=false

# Menu function using walker in dmenu mode
# Uses Omarchy-style dimensions: width 295, maxheight 600
menu() {
  local prompt="$1"
  local options="$2"
  local extra="$3"

  read -r -a args <<<"$extra"
  echo -e "$options" | walker --dmenu --width 295 --minheight 1 --maxheight 600 -p "$prompt…" "${args[@]}" 2>/dev/null
}

# Back navigation helper
back_to() {
  local parent_menu="$1"

  if [[ "$BACK_TO_EXIT" == "true" ]]; then
    exit 0
  elif [[ -n "$parent_menu" ]]; then
    "$parent_menu"
  else
    show_main_menu
  fi
}

# =============================================================================
# LEARN MENU - Documentation and resources
# =============================================================================

show_learn_menu() {
  case $(menu "Learn" "  Keybindings\n  Hyprland Wiki\n  NixOS Manual\n  Home Manager") in
  *Keybindings*) keybindings-menu ;;
  *Hyprland*) xdg-open "https://wiki.hyprland.org/" 2>/dev/null ;;
  *NixOS*) xdg-open "https://nixos.org/manual/nixos/stable/" 2>/dev/null ;;
  *Home*) xdg-open "https://nix-community.github.io/home-manager/" 2>/dev/null ;;
  *) back_to show_main_menu ;;
  esac
}

# =============================================================================
# TRIGGER MENU - Actions to trigger (Capture, Share, Toggle)
# =============================================================================

show_trigger_menu() {
  case $(menu "Trigger" "  Capture\n  Share\n󰔎  Toggle") in
  *Capture*) show_capture_menu ;;
  *Share*) show_share_menu ;;
  *Toggle*) show_toggle_menu ;;
  *) back_to show_main_menu ;;
  esac
}

show_capture_menu() {
  case $(menu "Capture" "  Screenshot\n  Screenrecord\n󰃉  Color Picker") in
  *Screenshot*) show_screenshot_menu ;;
  *Screenrecord*) show_screenrecord_menu ;;
  *Color*) hyprpicker -a 2>/dev/null || notify-send "Color Picker" "hyprpicker not available" ;;
  *) back_to show_trigger_menu ;;
  esac
}

show_share_menu() {
  case $(menu "Share" "  Clipboard\n  File\n  Folder") in
  *Clipboard*)
    if command -v wl-paste &>/dev/null; then
      wl-paste | qrencode -o - | satty --filename - 2>/dev/null || notify-send "Share" "Clipboard shared"
    else
      notify-send "Share" "wl-paste not available"
    fi
    ;;
  *File*) nautilus --select 2>/dev/null ;;
  *Folder*) nautilus 2>/dev/null ;;
  *) back_to show_trigger_menu ;;
  esac
}

show_screenshot_menu() {
  case $(menu "Screenshot" "  Snap with Editing\n  Straight to Clipboard") in
  *Editing*)
    satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(hyprshot -m region --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled"
    ;;
  *Clipboard*)
    hyprshot -m region --clipboard 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled"
    ;;
  *) back_to show_capture_menu ;;
  esac
}

show_screenrecord_menu() {
  case $(menu "Screenrecord" "  Region\n  Region + Audio\n  Display\n  Display + Audio") in
  *"Region + Audio"*) notify-send "Screenrecord" "Recording region with audio..." ;;
  *Region*) notify-send "Screenrecord" "Recording region..." ;;
  *"Display + Audio"*) notify-send "Screenrecord" "Recording display with audio..." ;;
  *Display*) notify-send "Screenrecord" "Recording display..." ;;
  *) back_to show_capture_menu ;;
  esac
}

show_toggle_menu() {
  case $(menu "Toggle" "󱄄  Screensaver\n󰔎  Nightlight\n󱫖  Idle Lock\n󰍜  Waybar\n  Transparency\n  Gaps") in
  *Screensaver*)
    if pgrep -x hyprlock >/dev/null; then
      pkill hyprlock && notify-send "Screensaver" "Disabled"
    else
      hyprlock & notify-send "Screensaver" "Enabled"
    fi
    ;;
  *Nightlight*)
    if command -v toggle-nightlight &>/dev/null; then
      toggle-nightlight
    elif pgrep -x hyprsunset >/dev/null; then
      pkill hyprsunset && notify-send "Night Light" "Disabled"
    else
      hyprsunset & notify-send "Night Light" "Enabled"
    fi
    ;;
  *Idle*)
    if command -v toggle-idle &>/dev/null; then
      toggle-idle
    else
      if pgrep -x hypridle >/dev/null; then
        pkill hypridle && notify-send "Idle Lock" "Disabled"
      else
        hypridle & notify-send "Idle Lock" "Enabled"
      fi
    fi
    ;;
  *Waybar*)
    if pgrep -x waybar >/dev/null; then
      pkill waybar && notify-send "Waybar" "Hidden"
    else
      waybar & notify-send "Waybar" "Shown"
    fi
    ;;
  *Transparency*)
    if command -v toggle-transparency &>/dev/null; then
      toggle-transparency
    else
      notify-send "Toggle" "Transparency toggle not available"
    fi
    ;;
  *Gaps*)
    if command -v workspace-toggle-gaps &>/dev/null; then
      workspace-toggle-gaps
    else
      notify-send "Toggle" "Gap toggle not available"
    fi
    ;;
  *) back_to show_trigger_menu ;;
  esac
}

# =============================================================================
# STYLE MENU - Theming and appearance
# =============================================================================

show_style_menu() {
  case $(menu "Style" "󰸌  Theme Settings\n  Background\n  Hyprland Config\n󰔎  Night Light") in
  *Theme*)
    if command -v nix-colors &>/dev/null; then
      notify-send "Theme" "Opening theme configuration..."
    else
      notify-send "Theme" "Theme managed via NixOS configuration"
    fi
    ;;
  *Background*) nautilus ~/Pictures/Wallpapers 2>/dev/null || notify-send "Background" "Wallpapers folder not found" ;;
  *Hyprland*)
    if [[ -f ~/.config/hypr/hyprland.conf ]]; then
      ${EDITOR:-nvim} ~/.config/hypr/hyprland.conf
    else
      notify-send "Hyprland" "Config managed via NixOS"
    fi
    ;;
  *Night*)
    if command -v toggle-nightlight &>/dev/null; then
      toggle-nightlight
    elif pgrep -x hyprsunset >/dev/null; then
      pkill hyprsunset && notify-send "Night Light" "Disabled"
    else
      hyprsunset & notify-send "Night Light" "Enabled"
    fi
    ;;
  *) back_to show_main_menu ;;
  esac
}

# =============================================================================
# SETUP MENU - System configuration and settings
# =============================================================================

show_setup_menu() {
  case $(menu "Setup" "  Audio\n  WiFi\n󰂯  Bluetooth\n  Monitors\n  Keybindings\n  Config") in
  *Audio*) show_audio_menu ;;
  *WiFi*)
    rfkill unblock wifi 2>/dev/null
    kitty -e nmtui
    ;;
  *Bluetooth*)
    rfkill unblock bluetooth 2>/dev/null
    blueberry
    ;;
  *Monitors*) wdisplays ;;
  *Keybindings*) keybindings-menu ;;
  *Config*) show_setup_config_menu ;;
  *) back_to show_main_menu ;;
  esac
}

show_audio_menu() {
  case $(menu "Audio" "  Switch Output\n  Volume Mixer") in
  *Switch*)
    if command -v audio-switch &>/dev/null; then
      audio-switch
    else
      notify-send "Audio" "Audio switcher not available"
    fi
    ;;
  *Mixer*) kitty -e wiremix ;;
  *) back_to show_setup_menu ;;
  esac
}

show_setup_config_menu() {
  case $(menu "Config" "  Hyprland\n  Hypridle\n  Hyprlock\n  Hyprsunset\n󰌧  Walker\n󰍜  Waybar") in
  *Hyprland*)
    if [[ -f ~/.config/hypr/hyprland.conf ]]; then
      ${EDITOR:-nvim} ~/.config/hypr/hyprland.conf
    else
      notify-send "Config" "Managed via NixOS configuration"
    fi
    ;;
  *Hypridle*)
    if [[ -f ~/.config/hypr/hypridle.conf ]]; then
      ${EDITOR:-nvim} ~/.config/hypr/hypridle.conf && systemctl --user restart hypridle
    else
      notify-send "Config" "Managed via NixOS configuration"
    fi
    ;;
  *Hyprlock*)
    if [[ -f ~/.config/hypr/hyprlock.conf ]]; then
      ${EDITOR:-nvim} ~/.config/hypr/hyprlock.conf
    else
      notify-send "Config" "Managed via NixOS configuration"
    fi
    ;;
  *Hyprsunset*)
    if [[ -f ~/.config/hypr/hyprsunset.conf ]]; then
      ${EDITOR:-nvim} ~/.config/hypr/hyprsunset.conf && pkill hyprsunset && hyprsunset &
    else
      notify-send "Config" "Managed via NixOS configuration"
    fi
    ;;
  *Walker*)
    if [[ -f ~/.config/walker/config.toml ]]; then
      ${EDITOR:-nvim} ~/.config/walker/config.toml && systemctl --user restart walker
    else
      notify-send "Config" "Managed via NixOS configuration"
    fi
    ;;
  *Waybar*)
    if [[ -f ~/.config/waybar/config.jsonc ]]; then
      ${EDITOR:-nvim} ~/.config/waybar/config.jsonc && pkill waybar && waybar &
    else
      notify-send "Config" "Managed via NixOS configuration"
    fi
    ;;
  *) back_to show_setup_menu ;;
  esac
}

# =============================================================================
# UPDATE MENU - System updates and restarts
# =============================================================================

show_update_menu() {
  case $(menu "Update" "  NixOS Config\n  Process\n󰇅  Hardware\n  Password\n  Time") in
  *NixOS*) show_update_nixos_menu ;;
  *Process*) show_update_process_menu ;;
  *Hardware*) show_update_hardware_menu ;;
  *Password*) kitty -e passwd ;;
  *Time*) timedatectl && notify-send "Time" "Current system time displayed" ;;
  *) back_to show_main_menu ;;
  esac
}

show_update_nixos_menu() {
  case $(menu "NixOS Config" "  Rebuild System\n  Update Flake\n  Garbage Collect") in
  *Rebuild*) kitty -e sudo nixos-rebuild switch ;;
  *Update*) kitty -e nix flake update ;;
  *Garbage*) kitty -e nix-collect-garbage -d ;;
  *) back_to show_update_menu ;;
  esac
}

show_update_process_menu() {
  case $(menu "Restart Process" "  Hypridle\n  Hyprsunset\n󰌧  Walker\n󰍜  Waybar") in
  *Hypridle*) systemctl --user restart hypridle && notify-send "Process" "Hypridle restarted" ;;
  *Hyprsunset*) pkill hyprsunset && hyprsunset & notify-send "Process" "Hyprsunset restarted" ;;
  *Walker*) systemctl --user restart walker && notify-send "Process" "Walker restarted" ;;
  *Waybar*) pkill waybar && waybar & notify-send "Process" "Waybar restarted" ;;
  *) back_to show_update_menu ;;
  esac
}

show_update_hardware_menu() {
  case $(menu "Restart Hardware" "  Audio\n󱚾  WiFi\n󰂯  Bluetooth") in
  *Audio*) systemctl --user restart pipewire pipewire-pulse wireplumber && notify-send "Hardware" "Audio restarted" ;;
  *WiFi*) systemctl restart NetworkManager && notify-send "Hardware" "WiFi restarted" ;;
  *Bluetooth*) systemctl restart bluetooth && notify-send "Hardware" "Bluetooth restarted" ;;
  *) back_to show_update_menu ;;
  esac
}

# =============================================================================
# UTILITIES MENU - Quick access to common tools
# =============================================================================

show_utilities_menu() {
  case $(menu "Utilities" "  File Manager\n  Terminal\n  System Monitor\n  Calculator\n  Text Editor") in
  *File*) nautilus ;;
  *Terminal*) kitty ;;
  *Monitor*) kitty -e btop ;;
  *Calculator*) gnome-calculator ;;
  *Editor*) gnome-text-editor ;;
  *) back_to show_main_menu ;;
  esac
}

# =============================================================================
# SYSTEM MENU - Power and system control
# =============================================================================

show_system_menu() {
  case $(menu "System" "  Lock\n󱄄  Screensaver\n󰤄  Suspend\n󰜉  Restart\n󰐥  Shutdown") in
  *Lock*) hyprlock ;;
  *Screensaver*) hyprlock & notify-send "Screensaver" "Launching screensaver" ;;
  *Suspend*) systemctl suspend ;;
  *Restart*) systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
  *) back_to show_main_menu ;;
  esac
}

# =============================================================================
# MAIN MENU - Top-level menu matching Omarchy structure
# =============================================================================

show_main_menu() {
  case $(menu "Menu" "󰀻  Apps\n󰧑  Learn\n󱓞  Trigger\n  Style\n  Setup\n  Update\n  Utilities\n  System") in
  *Apps*) walker ;;
  *Learn*) show_learn_menu ;;
  *Trigger*) show_trigger_menu ;;
  *Style*) show_style_menu ;;
  *Setup*) show_setup_menu ;;
  *Update*) show_update_menu ;;
  *Utilities*) show_utilities_menu ;;
  *System*) show_system_menu ;;
  esac
}

# =============================================================================
# ENTRY POINT - Allow direct menu access or show main menu
# =============================================================================

# Helper function to route to specific menus
go_to_menu() {
  case "${1,,}" in
  apps) walker ;;
  learn) show_learn_menu ;;
  trigger) show_trigger_menu ;;
  capture) show_capture_menu ;;
  share) show_share_menu ;;
  toggle) show_toggle_menu ;;
  screenshot) show_screenshot_menu ;;
  screenrecord) show_screenrecord_menu ;;
  style) show_style_menu ;;
  setup) show_setup_menu ;;
  update) show_update_menu ;;
  utilities) show_utilities_menu ;;
  system) show_system_menu ;;
  *) show_main_menu ;;
  esac
}

# Main entry point
if [[ -n "$1" ]]; then
  BACK_TO_EXIT=true
  go_to_menu "$1"
else
  show_main_menu
fi