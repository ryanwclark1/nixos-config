{
  pkgs,
  ...
}:

{
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      # plugins = [ pkgs.rofi-calc pkgs.rofi-emoji ];
      extraConfig = {
        bw = 1;
        columns = 2;
        icon-theme = "Papirus-Dark";
      };
      extraConfig = {
        modi = "drun";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        # display-emoji = "   Emoji ";
        # display-calc = "   Calc ";
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