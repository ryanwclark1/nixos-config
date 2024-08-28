{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    file.".config/rofi" = {
      source = ./config;
      recursive = true;
    };
  };

  programs = {
    rofi =
    let
      alacrity = lib.getExe pkgs.alacritty;
    in {
      enable = true;
      package = pkgs.rofi-wayland;
      # configPath = "${config.xdg.configHome}/rofi/config.rasi";
      # cycle = true;
      # font = "JetBrainsMono";
      # location = "center";
      # terminal = "${alacrity}";
      # xoffset = 0;
      # yoffset = 0;
      # plugins = [
      #   pkgs.rofi-calc
      #   pkgs.rofi-emoji-wayland
      # ];
      # extraConfig = {
      #   bw = 1;
      #   columns = 2;
      #   icon-theme = "Papirus-Dark";
      #   modi = "drun,ssh";
      #   show-icons = true;
      #   drun-display-format = "{icon} {name}";
      #   disable-history = false;
      #   hide-scrollbar = true;
      #   display-drun = "   Apps ";
      #   display-run = "   Run ";
      #   display-emoji = "   Emoji ";
      #   display-calc = "   Calc ";
      #   display-filebrowser = "FILES";
      #   display-window = "WINDOW";
      #   sidebar-mode = true;
      #   hover-select = false;
      #   scroll-method = 1;
      #   me-select-entry = "";
      #   me-accept-entry = "MousePrimary";
      #   window-format = "{w} · {c} · {t}";
      # };
      # theme = {
      #   "@theme" = "base";
      #   window = {
      #     width = "900px";
      #     x-offset = "0px";
      #     y-offset = "0px";
      #     spacing = "0px";
      #     padding = "0px";
      #     margin = "0px";
      #     color = "#FFFFFF";
      #     border = "3px";
      #     border-color = "#FFFFFF";
      #     cursor = "default";
      #     transparency = "real";
      #     location = "center";
      #     anchor = "center";
      #     fullscreen = false;
      #     enabled = true;
      #     border-radius = "10px";
      #     # background-color = "transparent";
      #   };

      #   mainbox = {
      #     enabled = true;
      #     orientation = "horizontal";
      #     spacing = "0px";
      #     margin = "0px";
      #     # background-color = @background;
      #     children = [
      #       "imagebox"
      #       "listbox"
      #     ];
      #   };

      #   imagebox = {
      #     padding = "18px";
      #     background-color = "transparent";
      #     orientation = "vertical";
      #     children = [
      #       "inputbar"
      #       "dummy"
      #       "mode-switcher"
      #     ];
      #   };

      #   listbox = {
      #     spacing = "20px";
      #     background-color = "transparent";
      #     orientation = "vertical";
      #     children = [
      #       "message"
      #       "listview"
      #     ];
      #   };

      #   dummy = {
      #     background-color = "transparent";
      #   };

      #   inputbar = {
      #     enabled = true;
      #     # text-color = @foreground;
      #     spacing = "10px";
      #     padding = "15px";
      #     border-radius = "10px";
      #     # border-color = @foreground;
      #     # background-color = @background;
      #     children = [
      #       "textbox-prompt-colon"
      #       "entry"
      #     ];
      #   };

      #   textbox-prompt-colon = {
      #     enabled = true;
      #     expand = false;
      #     str = "";
      #     padding = "0px 5px 0px 0px";
      #     background-color = "transparent";
      #     # text-color = inherit;
      #   };

      #   entry = {
      #     enabled = true;
      #     background-color = "transparent";
      #     # text-color = inherit;
      #     cursor = "text";
      #     placeholder = "Search";
      #     # placeholder-color = inherit;
      #   };

      #   mode-switcher ={
      #     enabled = true;
      #     spacing = "20px";
      #     background-color = "transparent";
      #     # text-color = @foreground;
      #   };

      #   button = {
      #     padding = "10px";
      #     border-radius = "10px";
      #     # background-color = @background;
      #     # text-color = inherit;
      #     cursor = "pointer";
      #     border = "0px";
      #   };

      #   # button selected = {
      #     # background-color = @color11;
      #     # text-color = @foreground;
      #   # };

      #   listview = {
      #     enabled = true;
      #     columns = 1;
      #     lines = 8;
      #     cycle = false;
      #     dynamic = false;
      #     scrollbar = false;
      #     layout = "vertical";
      #     reverse = false;
      #     fixed-height = true;
      #     fixed-columns = true;
      #     spacing = "0px";
      #     padding = "10px";
      #     margin = "0px";
      #     # background-color = @background;
      #     border = "0px";
      #   };

      #   element = {
      #     enabled = true;
      #     padding = "10px";
      #     margin = "5px";
      #     cursor = "pointer";
      #     # background-color = @background;
      #     border-radius = "10px";
      #     border = "3px";
      #   };

      #   # element normal.normal = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element normal.urgent = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element normal.active = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element selected.normal = {
      #   #   background-color = @color11;
      #   #   text-color = @foreground;
      #   # };

      #   # element selected.urgent = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element selected.active = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element alternate.normal = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element alternate.urgent = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element alternate.active = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   element-icon = {
      #     # background-color = "transparent";
      #     # text-color = inherit;
      #     size = "32px";
      #     # cursor = inherit;
      #   };

      #   element-text = {
      #     # background-color = "transparent";
      #     # text-color = inherit;
      #     # cursor = inherit;
      #     vertical-align = "0.5";
      #     horizontal-align = "0.0";
      #   };


      #   message = {
      #     background-color = "transparent";
      #     border = "0px";
      #     margin = "20px 0px 0px 0px";
      #     padding = "0px";
      #     spacing = "0px";
      #     border-radius =  "10px";
      #   };

      #   textbox = {
      #     padding = "15px";
      #     margin = "0px";
      #     border-radius = "0px";
      #     # background-color = @background;
      #     # text-color = @foreground;
      #     vertical-align = "0.5";
      #     horizontal-align = "0.0";
      #   };

      #   error-message = {
      #     padding = "15px";
      #     border-radius = "20px";
      #     # background-color = @background;
      #     # text-color = @foreground;
      #   };

      # };
      pass = {
        enable = true;
        package = pkgs.rofi-pass-wayland;
        stores = [
          "/home/administrator/.local/share/keyrings"
        ];
      };
    };
  };
}