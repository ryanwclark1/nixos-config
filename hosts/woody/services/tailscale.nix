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
    # extraSetFlags = [
    # ];
    extraUpFlags = [
      "--exit-node=homeassistant"
      "--exit-node-allow-lan-access"
      "--operator=administrator"
      "--advertise-tags=tag:client,tag:desktop,tag:no-exit"
      "--accept-routes=true"
    ];
  };

  # Prometheus Service Discovery for Tailscale.
  environment.systemPackages = with pkgs; [
    tailscalesd
    trayscale
  ];
}
