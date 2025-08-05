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
    settings = {
      server = {
        secret_key = "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456";
      };
    };
  };
}
