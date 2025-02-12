{
  ...
}:

{
  services = {
    # Enable SPICE guest agent functionalities (clipboard sharing, resolution resizing, etc.)
    # spice-vdagentd.enable = true;

    # Enable WebDAV support over SPICE for file sharing between host and guest
    spice-webdavd = {
      enable = true;
    };

    # Enable automatic display configuration for SPICE sessions
    spice-autorandr = {
      enable = true;
    };
  };
}
