# https://docs.syncthing.net/users/config.html
{
  config,
  pkgs,
  ...
}:
let
  user = "administrator";
in
{

  services = {
    syncthing = {
      enable = true;
      # dataDir = "/home/administrator";
      configDir = "${config.home.homeDirectory}/syncthing";
      group = "syncthing";
      guiAddress = "127.0.0.1:8384";
      openDefaultPorts = true;
      package = pkgs.syncthing;
      settings = {
        gui = {
          theme = "black";
        };
        folders = {
          "${config.home.homeDirectory}/Documents" = {
            id = "documents_sync";
          };
          "${config.home.homeDirectory}/Pictures" = {
            id = "pictures_sync";
          };
          "${config.home.homeDirectory}/Videos" = {
            id = "videos_sync";
          };
        };
      };
      systemService = true;
      user = "${user}";
    };
  };
}