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
       git = {
          log.order = "default";
          fetchAll = false;
       };
      };
    };
  };
}