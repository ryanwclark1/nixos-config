{ pkgs, ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Enable the Tailscale daemon
    useRoutingFeatures = "server";
    # Allow Tailscale to manage the firewall rules
    extraUpFlags = [
      "--accept-routes"
      "--advertise-exit-node"
      "--hostname=frametop"
    ];
  };

  # Make the tailscale command available to users
  environment.systemPackages = with pkgs; [
    tailscale
    jq
  ];

  # Open the Tailscale port in the firewall
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };
}
