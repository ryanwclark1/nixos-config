{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System menu using walker - adapted from omarchy-menu for NixOS
  
  home.packages = with pkgs; [
    # Main system menu script
    (writeShellScriptBin "system-menu" ''
      PATH="${pkgs.walker}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.systemd}/bin:${pkgs.kitty}/bin:$PATH"
      
      # Menu function using walker
      menu() {
        local prompt="$1"
        local options="$2"
        local extra="$3"
        
        read -r -a args <<<"$extra"
        echo -e "$options" | walker --dmenu -p "$prompt…" "''${args[@]}"
      }
      
      # Screenshot menu
      show_capture_menu() {
        case $(menu "Capture" "📷 Screenshot\n🎬 Screenrecord\n🎨 Color Picker") in
        *Screenshot*) show_screenshot_menu ;;
        *Screenrecord*) show_screenrecord_menu ;;
        *Color*) ${pkgs.hyprpicker}/bin/hyprpicker -a 2>/dev/null || notify-send "Color Picker" "hyprpicker not available" ;;
        *) show_main_menu ;;
        esac
      }
      
      # Screenshot submenu
      show_screenshot_menu() {
        case $(menu "Screenshot" "📷 Region\n🖼️ Window\n🖥️ Display") in
        *Region*) ${pkgs.satty}/bin/satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(${pkgs.hyprshot}/bin/hyprshot -m region --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled" ;;
        *Window*) ${pkgs.satty}/bin/satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(${pkgs.hyprshot}/bin/hyprshot -m window --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled" ;;
        *Display*) ${pkgs.satty}/bin/satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(${pkgs.hyprshot}/bin/hyprshot -m output --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled" ;;
        *) show_capture_menu ;;
        esac
      }
      
      # Screen recording submenu  
      show_screenrecord_menu() {
        case $(menu "Screenrecord" "🎬 Region\n🖥️ Fullscreen") in
        *Region*) screenrecord region ;;
        *Fullscreen*) screenrecord fullscreen ;;
        *) show_capture_menu ;;
        esac
      }
      
      # Audio menu
      show_audio_menu() {
        case $(menu "Audio" "🔊 Switch Output\n🔇 Toggle Mute\n🎚️ Volume Mixer") in
        *Switch*) audio-switch ;;
        *Mute*) audio-volume-mute ;;
        *Mixer*) ${pkgs.kitty}/bin/kitty -e ${pkgs.wiremix}/bin/wiremix ;;
        *) show_main_menu ;;
        esac
      }
      
      # System settings menu
      show_settings_menu() {
        case $(menu "Settings" "🔊 Audio\n📶 Network\n🔵 Bluetooth\n⚡ Power\n🖥️ Displays\n⌨️ Keybindings") in
        *Audio*) show_audio_menu ;;
        *Network*) ${pkgs.kitty}/bin/kitty -e ${pkgs.networkmanager}/bin/nmtui ;;
        *Bluetooth*) ${pkgs.blueberry}/bin/blueberry ;;
        *Power*) show_power_menu ;;
        *Displays*) ${pkgs.wdisplays}/bin/wdisplays ;;
        *Keybindings*) keybindings-menu ;;
        *) show_main_menu ;;
        esac
      }
      
      # Power menu
      show_power_menu() {
        case $(menu "Power" "🔒 Lock\n💤 Suspend\n🔄 Restart\n⏻ Shutdown") in
        *Lock*) ${pkgs.hyprlock}/bin/hyprlock ;;
        *Suspend*) systemctl suspend ;;
        *Restart*) systemctl reboot ;;
        *Shutdown*) systemctl poweroff ;;
        *) show_settings_menu ;;
        esac
      }
      
      # Toggle menu for various system states
      show_toggle_menu() {
        case $(menu "Toggle" "🔵 Bluetooth\n📶 WiFi\n🔊 Waybar\n🌙 Night Light") in
        *Bluetooth*) 
          if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
            rfkill unblock bluetooth && notify-send "Bluetooth" "Enabled"
          else
            rfkill block bluetooth && notify-send "Bluetooth" "Disabled" 
          fi
          ;;
        *WiFi*)
          if rfkill list wifi | grep -q "Soft blocked: yes"; then
            rfkill unblock wifi && notify-send "WiFi" "Enabled"
          else
            rfkill block wifi && notify-send "WiFi" "Disabled"
          fi
          ;;
        *Waybar*)
          if pgrep -x waybar >/dev/null; then
            pkill waybar && notify-send "Waybar" "Hidden"
          else  
            waybar & notify-send "Waybar" "Shown"
          fi
          ;;
        *Night*)
          if pgrep -x hyprsunset >/dev/null; then
            pkill hyprsunset && notify-send "Night Light" "Disabled"
          else
            ${pkgs.hyprsunset}/bin/hyprsunset & notify-send "Night Light" "Enabled"
          fi
          ;;
        *) show_main_menu ;;
        esac
      }
      
      # Quick utilities menu
      show_utilities_menu() {
        case $(menu "Utilities" "📁 File Manager\n💻 Terminal\n📊 System Monitor\n🧮 Calculator\n📝 Text Editor") in
        *File*) ${pkgs.nautilus}/bin/nautilus ;;
        *Terminal*) ${pkgs.kitty}/bin/kitty ;;
        *Monitor*) ${pkgs.kitty}/bin/kitty -e ${pkgs.btop}/bin/btop ;;
        *Calculator*) ${pkgs.gnome-calculator}/bin/gnome-calculator ;;
        *Editor*) ${pkgs.gnome-text-editor}/bin/gnome-text-editor ;;
        *) show_main_menu ;;
        esac
      }
      
      # Main menu
      show_main_menu() {
        case $(menu "System Menu" "🚀 Apps\n📷 Capture\n⚙️ Settings\n🔀 Toggle\n🛠️ Utilities\n⚡ Power") in
        *Apps*) walker ;;
        *Capture*) show_capture_menu ;;
        *Settings*) show_settings_menu ;;  
        *Toggle*) show_toggle_menu ;;
        *Utilities*) show_utilities_menu ;;
        *Power*) show_power_menu ;;
        esac
      }
      
      # Entry point
      if [[ -n "$1" ]]; then
        case "''${1,,}" in
        apps) walker ;;
        capture) show_capture_menu ;;
        settings) show_settings_menu ;;
        power) show_power_menu ;;
        toggle) show_toggle_menu ;;
        utilities) show_utilities_menu ;;
        *) show_main_menu ;;
        esac
      else
        show_main_menu
      fi
    '')
  ];
}