{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = [
    pkgs.wireguard-tools
  ];

  sops.secrets = {
    wg-key = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-wg-server = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ]; # Clients and peers can use the same port, see listenport
  };
  # Enable WireGuard
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      ips = [ "10.11.11.17/32" ];
      listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

      privateKeyFile = config.sops.secrets.wg-key.path;

      peers = [
        {
          name = "AccentSplitTunnel";
          publicKey = "zgZzw342CCMDrIjW2/sFf7ixAYR881h6LOG8hVDoclw=";

          # Forward all the traffic via VPN.
          allowedIPs = [
            "172.22.22.0/24"
            "172.22.3.0/24"
          ];

          # Set this to the server IP and port.
          endpoint = "$(cat ${config.sops.secrets.accent-wg-server.path})"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };

}