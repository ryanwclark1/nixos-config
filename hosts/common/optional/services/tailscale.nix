{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    # Automatically start Tailscale on boot
    # This ensures the service is enabled and started with the system
    useRoutingFeatures = lib.mkDefault "client";
    openFirewall = true;
    port = 41641;

    # For automatic connection, uncomment and set your auth key:
    # authKeyFile = "/path/to/tailscale-auth-key";
    # OR use environment variable:
    # authKey = "tskey-...";
  };

  # Make tailscale command available to users
  environment.systemPackages = with pkgs; [
    tailscale
    jq
  ];

  # Ensure Tailscale interface is trusted in firewall
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # Tailscale will start automatically with the system
  # No need to wait for network-online.target as it can handle
  # network connectivity changes dynamically
}
