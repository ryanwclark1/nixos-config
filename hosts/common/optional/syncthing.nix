# https://docs.syncthing.net/users/config.html
{
  # lib,
  pkgs,
  ...
}:

{

  services = {
    syncthing = {
      enable = true;
      dataDir = "/home/administrator";
      group = "syncthing";
      guiAddress = "127.0.0.1:8384";
      openDefaultPorts = true;
      package = pkgs.syncthing;
      settings = {
        gui = {
          theme = "black";
        };
        folders = {
          "/home/administrator/Documents" ={
            id = "documents_sync";
          };
          "/home/administrator/Pictures" ={
            id = "pictures_sync";
          };
          "/home/administrator/Videos" ={
            id = "videos_sync";
          };
        };
      };
      systemService = true;
      user = "administrator";
    };
  };
}