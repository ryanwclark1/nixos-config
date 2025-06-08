{
  config,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
  domain = "techcasa.io";
in
{
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      appendNameservers = [
        "10.10.100.1"  # Local DNS
        "1.1.1.1"      # Cloudflare DNS
        "1.0.0.1"      # Cloudflare DNS backup
        "100.100.100.100"  # Tailscale DNS
      ];
      logLevel = "INFO";
      wifi = {
        powersave = false;
        backend = "wpa_supplicant";
      };
      ethernet = {
        macAddress = "random";
      };
    };
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP
        443   # HTTPS
        5353  # mDNS
      ];
      allowedUDPPorts = [
        5353  # mDNS
      ];
      connectionTrackingModules = [
        "ftp"
        "irc"
        "sane"
        "sip"
        "tftp"
        "amanda"
        "h323"
        "netbios_sn"
        "pptp"
        "snmp"
      ];
    };
    fqdn = "${hostName}.${domain}";
    search = [
      "${domain}"
    ];
    resolvconf.enable = false;
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    fallbackDns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    extraConfig = ''
      DNS=1.1.1.1 1.0.0.1
      DNSOverTLS=opportunistic
      MulticastDNS=yes
    '';
  };

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
}
