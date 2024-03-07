{
  pkgs,
  ...
}:

{
  programs = {
    lazygit = {
      enable = true;
      package = pkgs.lazygit;
      settings = {
        gui.theme = {
          lightTheme = true;
          activeBorderColor = [ "blue" "bold" ];
          inactiveBorderColor = [ "black" ];
          selectedLineBgColor = [ "default" ];
       };
      };
    };
  };
}