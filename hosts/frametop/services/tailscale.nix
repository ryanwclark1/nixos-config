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
      "--accept-dns=false"
      "--accept-risk=all"
      "--accept-routes=true"
      "--advertise-connector=false"
      "--advertise-exit-node=false"
      "--exit-node=homeassistant"
      "--exit-node-allow-lan-access=true"
      "--force-reauth=false"
      "--json=false"
      "--login-server=https://controlplane.tailscale.com"
      "--netfilter-mode=on"
      "--operator=administrator"
      "--qr=false"
      "--reset=true"
      "--shields-up=false"
      "--snat-subnet-routes=false"
      "--ssh=false"
      "--stateful-filtering=false"
      "--timeout=0s"
    ];
  };

  # Prometheus Service Discovery for Tailscale.
  environment.systemPackages = [
    pkgs.tailscalesd
  ];
}
