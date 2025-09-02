{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Hyprland utility scripts
  
  home.packages = with pkgs; [
    # Get current working directory of active terminal
    (writeShellScriptBin "terminal-cwd" ''
      PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.gawk}/bin:${pkgs.coreutils}/bin:$PATH"
      
      # Get the PID of the currently active window
      terminal_pid=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.pid // empty' 2>/dev/null)
      
      if [[ -z "$terminal_pid" || "$terminal_pid" == "null" ]]; then
        # Fallback: try the old method without JSON
        terminal_pid=$(hyprctl activewindow 2>/dev/null | awk '/pid:/ {print $2}' | head -n1)
      fi
      
      if [[ -n "$terminal_pid" && "$terminal_pid" != "null" ]]; then
        # Find child shell process of the terminal
        shell_pid=$(pgrep -P "$terminal_pid" | head -n1)
        
        if [[ -n "$shell_pid" ]]; then
          # Get the current working directory of the shell process
          if cwd=$(readlink -f "/proc/$shell_pid/cwd" 2>/dev/null); then
            echo "$cwd"
          else
            echo "$HOME"
          fi
        else
          echo "$HOME"
        fi
      else
        echo "$HOME"
      fi
    '')
    
    # Open a new terminal in the current terminal's working directory
    (writeShellScriptBin "terminal-here" ''
      current_dir=$(terminal-cwd)
      cd "$current_dir" && ${pkgs.kitty}/bin/kitty &
    '')
    
    # Close all windows in Hyprland
    (writeShellScriptBin "close-all-windows" ''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
      
      # Get all window addresses
      windows=$(hyprctl clients -j | jq -r '.[].address')
      
      if [[ -z "$windows" ]]; then
        notify-send "Close All Windows" "No windows to close" -t 1000
        exit 0
      fi
      
      window_count=$(echo "$windows" | wc -l)
      
      # Close each window
      echo "$windows" | while read -r address; do
        [[ -n "$address" ]] && hyprctl dispatch closewindow address:"$address"
      done
      
      notify-send "Close All Windows" "Closed $window_count windows" -t 2000
    '')
    
    # Get window information for current active window
    (writeShellScriptBin "window-info" ''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:$PATH"
      
      window_info=$(hyprctl activewindow -j 2>/dev/null)
      
      if [[ -n "$window_info" && "$window_info" != "null" ]]; then
        echo "Active Window Information:"
        echo "========================="
        echo "Title: $(echo "$window_info" | jq -r '.title // "Unknown"')"
        echo "Class: $(echo "$window_info" | jq -r '.class // "Unknown"')" 
        echo "PID: $(echo "$window_info" | jq -r '.pid // "Unknown"')"
        echo "Workspace: $(echo "$window_info" | jq -r '.workspace.name // "Unknown"')"
        echo "Position: $(echo "$window_info" | jq -r '.at[0]'),$(echo "$window_info" | jq -r '.at[1]')"
        echo "Size: $(echo "$window_info" | jq -r '.size[0]')x$(echo "$window_info" | jq -r '.size[1]')"
        echo "Floating: $(echo "$window_info" | jq -r '.floating // false')"
        echo "Fullscreen: $(echo "$window_info" | jq -r '.fullscreen // false')"
      else
        echo "No active window found"
      fi
    '')
    
    # Smart workspace switcher (create workspace if it doesn't exist)
    (writeShellScriptBin "workspace-switch" ''
      PATH="${pkgs.hyprland}/bin:$PATH"
      
      workspace="$1"
      if [[ -z "$workspace" ]]; then
        echo "Usage: workspace-switch <workspace_number>"
        exit 1
      fi
      
      # Switch to workspace (Hyprland will create it if it doesn't exist)
      hyprctl dispatch workspace "$workspace"
    '')
  ];
}