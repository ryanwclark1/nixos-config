# https://docs.syncthing.net/users/config.html
{
  # lib,
  pkgs,
  ...
}:
let
  user = "administrator";
  homeDirectory = "/home/${user}";
in
{

  services.syncthing = {
    enable = true;
    # dataDir = "/home/administrator";
    configDir = "${homeDirectory}/.config/syncthing";
    group = "syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true;
    package = pkgs.syncthing;
    settings = {
      gui = {
        theme = "black";
      };
      folders = {
        "${homeDirectory}/Documents" = {
          id = "documents_sync";
        };
        "${homeDirectory}/Pictures" = {
          id = "pictures_sync";
        };
        "${homeDirectory}/Videos" = {
          id = "videos_sync";
        };
      };
    };
    systemService = true;
    user = "${user}";
  };
}