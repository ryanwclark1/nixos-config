{ config, lib, pkgs, ... }:

{
  # Hide system/configuration applications from the application launcher
  # These are useful tools but clutter the launcher menu for end users
  
  xdg.desktopEntries = {
    # System monitoring tools (better accessed via terminal/shortcuts)
    "amdgpu_top" = {
      name = "AMDGPU Top";
      exec = "amdgpu_top";
      settings = {
        Hidden = "true";
      };
    };
    
    "amdgpu_top-tui" = {
      name = "AMDGPU Top TUI";
      exec = "amdgpu_top --tui";
      settings = {
        Hidden = "true";
      };
    };
    
    "btop" = {
      name = "btop";
      exec = "btop";
      settings = {
        Hidden = "true";
      };
    };
    
    "htop" = {
      name = "htop";  
      exec = "htop";
      settings = {
        Hidden = "true";
      };
    };
    
    # Bluetooth configuration tools (better accessed via system settings)
    "blueman-adapters" = {
      name = "Bluetooth Adapters";
      exec = "blueman-adapters";
      settings = {
        Hidden = "true";
      };
    };
    
    # CUPS printer configuration (typically accessed when needed)
    "cups" = {
      name = "Manage Printing";
      exec = "xdg-open http://localhost:631/";
      settings = {
        Hidden = "true";
      };
    };
    
    # Font management tools (not frequently used)
    "com.github.FontManager.FontManager" = {
      name = "Font Manager";
      exec = "font-manager";
      settings = {
        Hidden = "true";
      };
    };
    
    "com.github.FontManager.FontViewer" = {
      name = "Font Viewer";
      exec = "font-viewer";
      settings = {
        Hidden = "true";
      };
    };
    
    # Audio control (better accessed via system controls)
    "com.saivert.pwvucontrol" = {
      name = "PipeWire Volume Control";
      exec = "pwvucontrol";
      settings = {
        Hidden = "true";
      };
    };
    
    # Hardware/system control tools
    "org.corectrl.CoreCtrl" = {
      name = "CoreCtrl";
      exec = "corectrl";
      settings = {
        Hidden = "true";
      };
    };
    
    # Geolocation demo tools
    "geoclue-demo-agent" = {
      name = "Geoclue Demo Agent";
      exec = "geoclue-demo-agent";
      settings = {
        Hidden = "true";
      };
    };
    
    "geoclue-where-am-i" = {
      name = "Where Am I?";
      exec = "geoclue-where-am-i";
      settings = {
        Hidden = "true";
      };
    };
    
    # NixOS documentation (better accessed via browser/terminal)
    "nixos-manual" = {
      name = "NixOS Manual";
      exec = "nixos-help";
      settings = {
        Hidden = "true";
      };
    };
    
    # File management internal tools
    "nautilus-autorun-software" = {
      name = "Software Autorun";
      exec = "nautilus-autorun-software";
      settings = {
        Hidden = "true";
      };
    };
    
    # Xwayland (system component, not user application)
    "org.freedesktop.Xwayland" = {
      name = "Xwayland";
      exec = "Xwayland";
      settings = {
        Hidden = "true";
      };
    };
    
    # File manager settings tools (better accessed from within file manager)
    "thunar-settings" = {
      name = "File Manager Preferences";
      exec = "thunar-settings";
      settings = {
        Hidden = "true";
      };
    };
    
    "thunar-volman-settings" = {
      name = "Removable Drives and Media";
      exec = "thunar-volman-settings";
      settings = {
        Hidden = "true";
      };
    };
  };
}