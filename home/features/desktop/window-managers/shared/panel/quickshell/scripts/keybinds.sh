# keybinds.sh - Parse Hyprland keybindings into JSON

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && ! grep -qi "hyprland" <<<"${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}"; then
    echo "[]"
    exit 0
fi

KEYBIND_DIR="$HOME/nixos-config/home/features/desktop/window-managers/hyprland/conf/keybindings"

if [ ! -d "$KEYBIND_DIR" ]; then
    # Fallback to absolute path if needed
    KEYBIND_DIR="$HOME/.config/hypr/conf/keybindings"
fi

# Use jq to build the final JSON array
# Format: bind = MOD, KEY, DISPATCHER, ARGS # DESCRIPTION
output=$(grep -h "^bind =" "$KEYBIND_DIR"/*.conf | while read -r line; do
    # Extract the part before the comment and the comment itself
    cmd_part=$(echo "$line" | cut -d'#' -f1 | sed 's/^bind = //')
    comment_part=$(echo "$line" | grep -o '#.*' | sed 's/^#\s*//')
    
    # Split cmd_part: MOD, KEY, DISPATCHER, ARGS
    IFS=',' read -r mod key disp args <<< "$cmd_part"
    
    mod=$(echo "$mod" | xargs)
    key=$(echo "$key" | xargs)
    disp=$(echo "$disp" | xargs)
    args=$(echo "$args" | xargs)
    
    # Clean up MOD name
    mod_display=$(echo "$mod" | sed 's/\$mainMod/SUPER/')
    
    if [[ -n "$key" ]]; then
        name="$mod_display + $key"
        desc="${comment_part:-$disp $args}"
        
        name_esc=$(echo "$name" | jq -R .)
        desc_esc=$(echo "$desc" | jq -R .)
        disp_esc=$(echo "$disp" | jq -R .)
        args_esc=$(echo "$args" | jq -R .)
        
        echo "{\"name\":$name_esc,\"desc\":$desc_esc,\"disp\":$disp_esc,\"args\":$args_esc}"
    fi
done | jq -s '.')

echo "$output"
