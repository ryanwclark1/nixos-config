{
  config,
  pkgs,
  lib,
  ...
}:
with lib;

{
  options.hyprland2.enable = mkEnableOption "hyprland confgiruation settings";
  config = mkIf config.hyprland2.enable {
    home.username = "administrator";
    home.homeDirectory = "/home/administrator";
    home.stateVersion = "23.11";

    home.file.".config/stinger.mov".source = ./media/stinger.mov;
    home.file.".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    # home.file.".config/neofetch/config.conf".source = ./config/neofetch/config.conf;
    home.file.".vimrc".source = ./config/vimrc;
    home.file.".emoji".source = ./config/emoji;
    home.file.".face".source = ./config/face.jpg;
    home.file."Pictures/Wallpapers" = {
      source = ./media/wallpapers;
      recursive = true;
    };
    home.file.".local/share/fonts" = {
      source = ./fonts;
      recursive = true;
    };
    home.file.".config/rofi" = {
      source = ./config/rofi;
      recursive = true;
    };
    home.file.".config/swaync" = {
      source = ./config/swaync;
      recursive = true;
    };
    home.file.".config/hypr" = {
      source = ./config/hyprland;
      recursive = true;
    };

    xresources.properties = {
      "Xcursor.size" = 24;
    };


    home.packages = with pkgs; [
      lolcat cmatrix discord btop libvirt
      swww polkit_gnome grim slurp lm_sensors gnome.file-roller
      libnotify swaynotificationcenter rofi-wayland imv v4l-utils
      ydotool wl-clipboard socat cowsay lsd pkg-config transmission-gtk
      kdenlive meson glibc hugo gnumake ninja
      godot_4 rustup pavucontrol audacity zeroad xonotic
      openra font-awesome symbola noto-fonts-color-emoji material-icons
      spotify
      # Import Scripts
      (import ./scripts/emopicker9000.nix { inherit pkgs; })
      (import ./scripts/task-waybar.nix { inherit pkgs; })
      (import ./scripts/squirtle.nix { inherit pkgs; })
      (import ./scripts/wallsetter.nix { inherit pkgs; })
    ];

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    qt.enable = true;
    qt.platformTheme = "gtk";
    qt.style.name = "adwaita-dark";
    qt.style.package = pkgs.adwaita-qt;
    gtk = {
      enable = true;
      font = {
        name = "Ubuntu";
        size = 12;
        package = pkgs.ubuntu_font_family;
      };
      theme = {
        name = "Tokyonight-Storm-BL";
        package = pkgs.tokyo-night-gtk;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
      };
      gtk3.extraConfig = {
        Settings = ''
        gtk-application-prefer-dark-theme=1
        '';
      };
      gtk4.extraConfig = {
        Settings = ''
        gtk-application-prefer-dark-theme=1
        '';
      };
    };
    xdg = {
      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;
      profileExtra = ''
        #if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        #  exec Hyprland
        #fi
      '';
      sessionVariables = {

      };
      # shellAliases = {
        # sv="sudo vim";
        # flake-rebuild="sudo nixos-rebuild switch --flake ~/xxxxxxx/#workstation";
        # laptop-rebuild="sudo nixos-rebuild switch --flake ~/xxxxxxxx/#laptop";
        # v="vim";
        # ls="lsd";
        # ll="lsd -l";
        # la="lsd -a";
        # lal="lsd -al";
        # ".."="cd ..";
      # };
    };

    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [{
        layer = "top";
        position = "top";

        modules-left = [ "hyprland/window" ];
        modules-center = [ "network" "pulseaudio" "cpu" "hyprland/workspaces" "memory" "disk" "clock" ];
        modules-right = [ "custom/notification" "tray" ];
        "hyprland/workspaces" = {
        	format = "{icon}";
        	format-icons = {
            default = " ";
            active = " ";
            urgent = " ";
        	};
        	on-scroll-up = "hyprctl dispatch workspace e+1";
        	on-scroll-down = "hyprctl dispatch workspace e-1";
        };
        "clock" = {
          format = "{: %I:%M %p}";
        	tooltip = false;
        };
        "hyprland/window" = {
        	max-length = 60;
        	separate-outputs = false;
        };
        "memory" = {
        	interval = 5;
        	format = " {}%";
          tooltip = true;
        };
        "cpu" = {
        	interval = 5;
        	format = " {usage:2}%";
          tooltip = true;
        };
        "disk" = {
          format = "  {free}";
          tooltip = true;
        };
        "network" = {
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
          format-ethernet = ": {bandwidthDownOctets} : {bandwidthUpOctets}";
          format-wifi = "{icon} {signalStrength}%";
          format-disconnected = "󰤮";
          tooltip = false;
        };
        "tray" = {
          spacing = 12;
        };
        "pulseaudio" = {
          format = "{icon} {volume}% {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
        "custom/notification" = {
          tooltip = false;
          format = "{icon} {}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
         	};
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "task-waybar";
          escape = true;
        };
        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󱘖 {capacity}%";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
          on-click = "";
          tooltip = false;
        };
      }];
      style = ''
  	* {
  		font-size: 16px;
  		font-family: JetBrainsMono Nerd Font, Font Awesome, sans-serif;
      		font-weight: bold;
  	}
  	window#waybar {
  		    background-color: rgba(26,27,38,0);
      		border-bottom: 1px solid rgba(26,27,38,0);
      		border-radius: 0px;
  		    color: #f8f8f2;
  	}
  	#workspaces {
  		    background: linear-gradient(180deg, #414868, #24283b);
      		margin: 5px;
      		padding: 0px 1px;
      		border-radius: 15px;
      		border: 0px;
      		font-style: normal;
      		color: #15161e;
  	}
  	#workspaces button {
      		padding: 0px 5px;
      		margin: 4px 3px;
      		border-radius: 15px;
      		border: 0px;
      		color: #15161e;
      		background-color: #1a1b26;
      		opacity: 1.0;
      		transition: all 0.3s ease-in-out;
  	}
  	#workspaces button.active {
      		color: #15161e;
      		background: #7aa2f7;
      		border-radius: 15px;
      		min-width: 40px;
      		transition: all 0.3s ease-in-out;
      		opacity: 1.0;
  	}
  	#workspaces button:hover {
      		color: #15161e;
      		background: #7aa2f7;
      		border-radius: 15px;
      		opacity: 1.0;
  	}
  	tooltip {
    		background: #1a1b26;
    		border: 1px solid #7aa2f7;
    		border-radius: 10px;
  	}
  	tooltip label {
    		color: #c0caf5;
  	}
  	#window {
      		color: #565f89;
      		background: #1a1b26;
      		border-radius: 0px 15px 50px 0px;
      		margin: 5px 5px 5px 0px;
      		padding: 2px 20px;
  	}
  	#memory {
      		color: #2ac3de;
      		background: #1a1b26;
      		border-radius: 15px 50px 15px 50px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#clock {
      		color: #c0caf5;
      		background: #1a1b26;
      		border-radius: 15px 50px 15px 50px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#cpu {
      		color: #b4f9f8;
      		background: #1a1b26;
      		border-radius: 50px 15px 50px 15px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#disk {
      		color: #9ece6a;
      		background: #1a1b26;
      		border-radius: 15px 50px 15px 50px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#battery {
      		color: #f7768e;
      		background: #1a1b26;
      		border-radius: 15px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#network {
      		color: #ff9e64;
      		background: #1a1b26;
      		border-radius: 50px 15px 50px 15px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#tray {
      		color: #bb9af7;
      		background: #1a1b26;
      		border-radius: 15px 0px 0px 50px;
      		margin: 5px 0px 5px 5px;
      		padding: 2px 20px;
  	}
  	#pulseaudio {
      		color: #bb9af7;
      		background: #1a1b26;
      		border-radius: 50px 15px 50px 15px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
  	#custom-notification {
      		color: #7dcfff;
      		background: #1a1b26;
      		border-radius: 15px 50px 15px 50px;
      		margin: 5px;
      		padding: 2px 20px;
  	}
      '';
    };
    # programs.home-manager.enable = true;
  };

}
