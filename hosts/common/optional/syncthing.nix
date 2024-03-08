# https://docs.syncthing.net/users/config.html
{
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
        };
      };
      systemService = true;
      user = "syncthing";
    };
  };
}