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

    # Enhanced application launchers (overriding defaults for better UX)
    "nvim" = {
      name = "Neovim";
      exec = "ghostty --class=nvim --title=nvim -e nvim -- %F";
      terminal = false;
      mimeType = ["text/plain" "text/x-makefile" "text/x-c++hdr" "text/x-c++src" "text/x-chdr" "text/x-csrc" "text/x-java" "text/x-moc" "text/x-pascal" "text/x-tcl" "text/x-tex" "application/x-shellscript" "text/x-c" "text/x-c++"];
      categories = ["Utility" "TextEditor"];
    };

    "mpv" = {
      name = "mpv Media Player";
      exec = "mpv --player-operation-mode=pseudo-gui -- %U";
      terminal = false;
      mimeType = ["application/ogg" "application/x-ogg" "audio/ogg" "audio/vorbis" "audio/x-vorbis" "audio/x-vorbis+ogg" "video/ogg" "video/x-ogm" "video/x-ogm+ogg" "video/x-theora+ogg" "video/x-theora" "audio/x-speex" "audio/opus" "application/x-ogm-audio" "application/x-ogm-video" "audio/webm" "video/webm" "audio/x-matroska" "video/x-matroska" "video/mp4" "video/3gpp" "video/3gpp2" "audio/mp4" "audio/3gpp" "audio/3gpp2" "video/mp2t" "audio/mp2t" "video/avi" "video/msvideo" "video/x-msvideo" "video/quicktime" "video/x-anim" "video/x-avi" "video/x-ms-asf" "video/x-ms-wmv" "audio/x-ms-wma" "application/x-mplayer2" "audio/mpeg" "audio/x-mpeg" "audio/mp3" "audio/x-mp3" "audio/mpeg3" "audio/x-mpeg3" "audio/mpegurl" "audio/x-mpegurl" "audio/x-mpg" "video/mpeg" "video/x-mpeg" "video/x-mpeg2" "audio/x-scpls" "audio/x-wav" "audio/wav" "audio/flac" "audio/x-flac"];
      categories = ["AudioVideo" "Audio" "Video" "Player" "TV"];
    };
  };
}
