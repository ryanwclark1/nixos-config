{
  lib,
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    useRoutingFeatures = lib.mkDefault "client";
    openFirewall = true;
    port = 41641;
    extraSetFlags = [
      "--operator=administrator"
    ];
    extraUpFlags = [
      "---exit-node=homeassistant"
      "--exit-node-allow-lan-access"
    ];
  };

  environment.systemPackages = [
    pkgs.tailscaled
  ];
}
