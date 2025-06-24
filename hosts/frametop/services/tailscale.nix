{
  config,
  lib,
  pkgs,
  ...
}:

{
  # SOPS secrets for Tailscale auth
  # sops.secrets = {
  #   tailscale-auth-key = {
  #     sopsFile = ../../../../secrets/secrets.yaml;
  #     key = "tailscale-auth-keys.frametop";
  #   };
  # };

  # Common Tailscale configuration
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    # Automatically start Tailscale on boot
    # This ensures the service is enabled and started with the system
    useRoutingFeatures = "client";
    openFirewall = true;
    port = 41641;

    # Use encrypted auth key for automatic connection
    # authKeyFile = "$(cat ${config.sops.secrets.tailscale-auth-key.path})";
    # authKeyFile = config.sops.secrets.tailscale-auth-key.path;

    # Laptop-specific flags
    extraUpFlags = [
      "--accept-routes"
      "--advertise-tags=tag:client,tag:laptop,tag:no-exit"
      "--exit-node=woody"
      "--exit-node-allow-lan-access"
      "--accept-dns"
      "--shields-up"
      "--accept-risk=all"
      "--hostname=frametop"
    ];
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

  # Ensure Tailscale starts after SOPS secrets are decrypted
  # systemd.services.tailscaled = {
  #   after = [ "sops-nix.service" ];
  #   requires = [ "sops-nix.service" ];
  #   restartTriggers = [ config.sops.secrets.tailscale-auth-key.path ];
  # };
}
