{
  pkgs,
  ...
}:

{
  # Minimal Hyprland configuration files for system-level Hyprland
  # This provides just the essential files to get Hyprland working
  
  home.file = {
    # Main Hyprland config file
    ".config/hypr/hyprland.conf" = {
      text = ''
        # Minimal Hyprland Configuration for System-Level Installation
        
        # Basic input settings
        input {
            kb_layout = us
            follow_mouse = 1
            
            touchpad {
                natural_scroll = true
            }
        }
        
        # Basic general settings
        general {
            gaps_in = 5
            gaps_out = 20
            border_size = 2
            col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
            col.inactive_border = rgba(595959aa)
            layout = dwindle
        }
        
        # Basic decoration settings
        decoration {
            rounding = 10
            
            blur {
                enabled = true
                size = 3
                passes = 1
            }
            
            shadow {
                enabled = true
                range = 4
                render_power = 3
                color = rgba(1a1a1aee)
            }
        }
        
        # Basic animations
        animations {
            enabled = true
            bezier = myBezier, 0.05, 0.9, 0.1, 1.05
            animation = windows, 1, 7, myBezier
            animation = windowsOut, 1, 7, default, popin 80%
            animation = border, 1, 10, default
            animation = borderangle, 1, 8, default
            animation = fade, 1, 7, default
            animation = workspaces, 1, 6, default
        }
        
        # Dwindle layout settings
        dwindle {
            pseudotile = true
            preserve_split = true
        }
        
        # Basic keybindings
        $mainMod = SUPER
        
        # Application bindings
        bind = $mainMod, Return, exec, kitty
        bind = $mainMod, Q, killactive
        bind = $mainMod, E, exec, code
        bind = $mainMod, B, exec, google-chrome-stable
        bind = $mainMod, N, exec, nautilus
        bind = $mainMod, Space, exec, rofi -show drun
        
        # Window management
        bind = $mainMod, H, movefocus, l
        bind = $mainMod, L, movefocus, r
        bind = $mainMod, K, movefocus, u
        bind = $mainMod, J, movefocus, d
        
        # Window movement
        bind = $mainMod SHIFT, H, movewindow, l
        bind = $mainMod SHIFT, L, movewindow, r
        bind = $mainMod SHIFT, K, movewindow, u
        bind = $mainMod SHIFT, J, movewindow, d
        
        # Workspaces
        bind = $mainMod, 1, workspace, 1
        bind = $mainMod, 2, workspace, 2
        bind = $mainMod, 3, workspace, 3
        bind = $mainMod, 4, workspace, 4
        bind = $mainMod, 5, workspace, 5
        
        # Move to workspace
        bind = $mainMod SHIFT, 1, movetoworkspace, 1
        bind = $mainMod SHIFT, 2, movetoworkspace, 2
        bind = $mainMod SHIFT, 3, movetoworkspace, 3
        bind = $mainMod SHIFT, 4, movetoworkspace, 4
        bind = $mainMod SHIFT, 5, movetoworkspace, 5
        
        # Mouse bindings
        bindm = $mainMod, mouse:272, movewindow
        bindm = $mainMod, mouse:273, resizewindow
        
        # Basic monitor setup (adjust as needed)
        monitor = , preferred, auto, 1
      '';
    };
  };

  # Add essential Hyprland tools
  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    wlr-randr
  ];
}