{
  config,
  lib,
  pkgs,
  ...
}:

{
    environment.systemPackages = [
  ];

  services.searx = {
    enable = true;
  };
}
