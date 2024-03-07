# Configs https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
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