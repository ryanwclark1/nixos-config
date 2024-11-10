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
        enable = true;
        # startupFlags = [
        #   "--icon"
        # ];
      };
    };
  };
}