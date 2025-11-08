{
  lib,
  ...
}:

{
  programs = {
    gnupg.agent = {
      enable = lib.mkDefault true;
      enableSSHSupport = true;
    };
  };
}
