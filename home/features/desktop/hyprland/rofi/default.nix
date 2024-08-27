{
  lib,
  pkgs,
  ...
}:

{
  home = {
    # file.".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    # file.".emoji".source = ./config/emoji;
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
      configPath = "~/.config/rofi";
      cycle = true;
      # font = "";
      location = "center";
      terminal = "\${alacrity}";
      xoffset = 0;
      yoffset = 0;
      plugins = [
        pkgs.rofi-calc
        pkgs.rofi-emoji-wayland
      ];
      extraConfig = {
        bw = 1;
        columns = 2;
        icon-theme = "Papirus-Dark";
        modi = "drun,ssh";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-emoji = "   Emoji ";
        display-calc = "   Calc ";
        sidebar-mode = true;
      };
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