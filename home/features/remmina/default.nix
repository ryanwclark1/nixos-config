{
  pkgs,
  ...
}:

{
  services = {
    remmina = {
      enable = true;
      package = pkgs.remmina;
      addRdpMimeTypeAssoc = true;
      systemdService = {
        enable = false;
        startupFlags = [
          "--no-tray-icon"
        ];
      };
    };
  };
}
