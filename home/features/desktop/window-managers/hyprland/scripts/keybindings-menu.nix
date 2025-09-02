{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Interactive keybinding reference for Hyprland using walker
  
  home.packages = with pkgs; [
    (writeShellScriptBin "keybindings-menu" ''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:${pkgs.walker}/bin:$PATH"
      
      # Fetch dynamic keybindings from Hyprland
      dynamic_bindings() {
        hyprctl -j binds 2>/dev/null | \
          jq -r '.[] | {modmask, key, keycode, description, dispatcher, arg} | "\(.modmask),\(.key)@\(.keycode),\(.description),\(.dispatcher),\(.arg)"' | \
          sed -r \
              -e 's/null//' \
              -e 's/@0//' \
              -e 's/,@/,code:/' \
              -e 's/^0,/,/' \
              -e 's/^1,/SHIFT,/' \
              -e 's/^4,/CTRL,/' \
              -e 's/^5,/SHIFT CTRL,/' \
              -e 's/^8,/ALT,/' \
              -e 's/^9,/SHIFT ALT,/' \
              -e 's/^12,/CTRL ALT,/' \
              -e 's/^13,/SHIFT CTRL ALT,/' \
              -e 's/^64,/SUPER,/' \
              -e 's/^65,/SUPER SHIFT,/' \
              -e 's/^68,/SUPER CTRL,/' \
              -e 's/^69,/SUPER SHIFT CTRL,/' \
              -e 's/^72,/SUPER ALT,/' \
              -e 's/^73,/SUPER SHIFT ALT,/' \
              -e 's/^76,/SUPER CTRL ALT,/' \
              -e 's/^77,/SUPER SHIFT CTRL ALT,/'
      }
      
      # Parse and format keybindings
      parse_bindings() {
        awk -F, '
      {
          # Combine the modifier and key (first two fields)
          key_combo = $1 " + " $2;
      
          # Clean up: strip leading "+" if present, trim spaces
          gsub(/^[ \t]*\+?[ \t]*/, "", key_combo);
          gsub(/[ \t]+$/, "", key_combo);
      
          # Use description, if set
          action = $3;
      
          if (action == "") {
              # Reconstruct the command from the remaining fields
              for (i = 4; i <= NF; i++) {
                  action = action $i (i < NF ? "," : "");
              }
      
              # Clean up trailing commas, remove leading "exec, ", and trim
              sub(/,$/, "", action);
              gsub(/(^|,)[[:space:]]*exec[[:space:]]*,?/, "", action);
              gsub(/^[ \t]+|[ \t]+$/, "", action);
              gsub(/[ \t]+/, " ", key_combo);  # Collapse multiple spaces to one
      
              # Escape entities for display
              gsub(/&/, "\\&", action);
              gsub(/</, "\\<", action);
              gsub(/>/, "\\>", action);
              gsub(/"/, "\\\"", action);
          }
      
          if (action != "" && key_combo != " + ") {
              printf "%-35s → %s\n", key_combo, action;
          }
      }'
      }
      
      # Add some common keybindings that might not be captured dynamically
      add_common_bindings() {
        cat << 'EOF'
      SUPER + Return                      → Launch terminal
      SUPER + D                           → Application launcher  
      SUPER + Q                           → Close window
      SUPER + M                           → Exit Hyprland
      SUPER + V                           → Toggle floating
      SUPER + J                           → Toggle split
      SUPER + P                           → Pseudo tile
      SUPER + F                           → Fullscreen
      SUPER + SHIFT + S                   → Screenshot region
      SUPER + SHIFT + R                   → Screen record
      SUPER + L                           → Lock screen
      Alt + Tab                           → Cycle windows
      SUPER + 1-9                         → Switch workspace
      SUPER + SHIFT + 1-9                 → Move window to workspace
      SUPER + mouse_left                  → Move window
      SUPER + mouse_right                 → Resize window
      EOF
      }
      
      # Generate and display keybindings
      {
        # Get dynamic bindings from Hyprland
        if command -v hyprctl >/dev/null 2>&1; then
          dynamic_bindings | sort -u | parse_bindings
        fi
        
        # Add common bindings
        echo ""
        echo "# Common Keybindings:"
        add_common_bindings
      } | walker --dmenu -p 'Hyprland Keybindings' --keep-sort
    '')
  ];
}