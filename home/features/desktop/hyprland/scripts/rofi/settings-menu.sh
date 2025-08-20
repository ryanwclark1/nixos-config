#!/usr/bin/env bash

# Settings Menu for Hyprland
# Provides access to various system settings applications

# Icons for different settings categories
AUDIO_ICON="󰕾"      # Audio/Volume settings
BLUETOOTH_ICON="󰂯"  # Bluetooth settings
NETWORK_ICON="󰖩"    # Network settings  
DISPLAY_ICON="󰍹"    # Display settings
THEME_ICON="󰃟"      # Theme/Appearance settings
SYSTEM_ICON="󰒓"     # System settings
POWER_ICON="󰁹"      # Power management
PRIVACY_ICON="󰒃"    # Privacy settings

# Menu options with icons and descriptions
options=(
    "$AUDIO_ICON  Audio Settings"
    "$BLUETOOTH_ICON  Bluetooth Manager"
    "$NETWORK_ICON  Network Settings"
    "$DISPLAY_ICON  Display Configuration"
    "$THEME_ICON  Appearance & Themes"
    "$SYSTEM_ICON  System Information"
    "$POWER_ICON  Power Management"
    "$PRIVACY_ICON  Privacy Settings"
)

# Show rofi menu
choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Settings" -theme-str 'listview { lines: 8; }')

# Execute based on choice
case "$choice" in
    "$AUDIO_ICON  Audio Settings")
        pwvucontrol &
        ;;
    "$BLUETOOTH_ICON  Bluetooth Manager")
        blueman-manager &
        ;;
    "$NETWORK_ICON  Network Settings")
        nm-connection-editor &
        ;;
    "$DISPLAY_ICON  Display Configuration")
        # Use wdisplays for Wayland display management if available, otherwise arandr
        if command -v wdisplays >/dev/null; then
            wdisplays &
        elif command -v arandr >/dev/null; then
            arandr &
        else
            notify-send "Settings" "No display configuration tool found"
        fi
        ;;
    "$THEME_ICON  Appearance & Themes")
        # Try different theme managers in order of preference
        if command -v lxappearance >/dev/null; then
            lxappearance &
        elif command -v qt5ct >/dev/null; then
            qt5ct &
        elif command -v qt6ct >/dev/null; then
            qt6ct &
        else
            notify-send "Settings" "No theme manager found"
        fi
        ;;
    "$SYSTEM_ICON  System Information")
        # Show system information in terminal
        kitty -e sh -c 'neofetch && echo "Press any key to exit..." && read -n 1' &
        ;;
    "$POWER_ICON  Power Management")
        # Try different power management tools
        if command -v gnome-power-statistics >/dev/null; then
            gnome-power-statistics &
        else
            # Show power info in terminal as fallback
            kitty -e sh -c 'upower -i $(upower -e | grep "BAT") && echo "Press any key to exit..." && read -n 1' &
        fi
        ;;
    "$PRIVACY_ICON  Privacy Settings")
        # Open privacy-related settings
        if command -v gnome-control-center >/dev/null; then
            gnome-control-center privacy &
        else
            notify-send "Settings" "No privacy settings manager available"
        fi
        ;;
    *)
        # If nothing selected or ESC pressed, exit
        exit 0
        ;;
esac