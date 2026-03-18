{
  config,
  lib,
  pkgs,
  ...
}:

let
  wgEndpointPeer = "zgZzw342CCMDrIjW2/sFf7ixAYR881h6LOG8hVDoclw=";
in
{
  environment.systemPackages = [
    pkgs.wireguard-tools
  ];

  # Override ownership/permissions for WireGuard secrets (defined globally)
  sops.secrets = {
    wg-key = {
      owner = "systemd-network";
      group = "systemd-network";
      mode = "0400";
    };
    accent-wg-server = {
      owner = "systemd-network";
      group = "systemd-network";
      mode = "0400";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ]; # WireGuard port
  };

  # Enable WireGuard
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      ips = [ "10.11.11.17/32" ];
      listenPort = 51820; # to match firewall allowedUDPPorts

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

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];

      # `networking.wireguard` does not shell-expand endpoint strings, so keep
      # endpoint material in a secret and apply it after the interface comes up.
      postSetup = ''
        endpoint="$(tr -d '[:space:]' < ${config.sops.secrets.accent-wg-server.path})"
        host="''${endpoint%:*}"
        port="''${endpoint##*:}"

        if [ -z "$host" ] || [ -z "$port" ] || [ "$host" = "$endpoint" ]; then
          echo "Invalid WireGuard endpoint format in accent-wg-server secret" >&2
          exit 1
        fi

        resolved_ip=""
        for _attempt in 1 2 3 4 5; do
          resolved_ip="$(${pkgs.getent}/bin/getent ahostsv4 "$host" | ${pkgs.gawk}/bin/awk 'NR == 1 { print $1; exit }')"
          if [ -n "$resolved_ip" ]; then
            break
          fi
          sleep 2
        done

        if [ -n "$resolved_ip" ]; then
          ${pkgs.wireguard-tools}/bin/wg set wg0 peer ${wgEndpointPeer} endpoint "$resolved_ip:$port"
        else
          echo "Warning: unable to resolve WireGuard endpoint $host after retries; leaving peer endpoint unchanged" >&2
        fi
      '';
    };
  };

  # Ensure WireGuard starts after SOPS secrets are decrypted
  # This is important for services that depend on encrypted secrets
  # Extend the auto-generated service without replacing it
  systemd.services.wireguard-wg0 = {
    after = lib.mkAfter [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = lib.mkAfter [
      "network-online.target"
      "sops-nix.service"
    ];
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = "10s";
    restartTriggers = [
      config.sops.secrets.wg-key.path
      config.sops.secrets.accent-wg-server.path
    ];
  };
}
