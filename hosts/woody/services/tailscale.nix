{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Common Tailscale configuration
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    # Automatically start Tailscale on boot
    # This ensures the service is enabled and started with the system
    useRoutingFeatures = "server";
    openFirewall = true;
    port = 41641;

    # Use encrypted auth key for automatic connection
    # authKeyFile = config.sops.secrets.tailscale-auth-key.path;

    # Desktop-specific flags
    extraUpFlags = [
      "--operator=administrator"
      "--advertise-tags=tag:server,tag:desktop,tag:exit-node"
      "--accept-routes"
      "--advertise-exit-node"
      "--accept-dns"
      "--ssh"
      "--stateful-filtering"
      "--accept-risk=all"
      "--hostname=woody"
    ];
  };

  # Make tailscale command available to users
  environment.systemPackages = with pkgs; [
    tailscale
    jq
    tailscalesd

  ];

  # Ensure Tailscale interface is trusted in firewall
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };

}
