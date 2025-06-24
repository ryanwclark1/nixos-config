{
  config,
  lib,
  ...
}:
let
  inherit (config.networking) hostName domain;
in
{
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      appendNameservers = [
        "10.10.100.1" # Local DNS
        "1.1.1.1" # Cloudflare DNS
        "1.0.0.1" # Cloudflare DNS backup
        "100.100.100.100" # Tailscale DNS
      ];
      logLevel = "INFO";
      wifi = {
        powersave = false;
        backend = "wpa_supplicant";
      };
      ethernet = {
        macAddress = "random";
      };
      # Configure IPv6 privacy extensions through connection profiles
      ensureProfiles.profiles = {
        "default" = {
          connection = {
            id = "default";
            type = "ethernet";
          };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
          };
        };
      };
      # Additional NetworkManager settings
      unmanaged = [
        "docker0"
        "veth*"
        "br-*"
        "virbr*"
      ];
    };
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
        5353 # mDNS
        8080 # Alternative HTTP port
        8443 # Alternative HTTPS port
      ];
      allowedUDPPorts = [
        5353 # mDNS
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
      # Additional firewall hardening
      checkReversePath = "loose";
      logReversePathDrops = true;
      # Trust local interfaces
      trustedInterfaces = [
        "lo"
        "docker0"
        "virbr0"
      ];
    };
    # Use global domain configuration
    fqdn = "${hostName}.${domain}";
    search = [
      "${domain}"
    ];
    resolvconf.enable = false;

    # Network security settings
    enableIPv6 = true;
    # IPv6 privacy extensions are configured via NetworkManager profiles above
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
      LLMNR=yes
      # Additional DNS settings
      Cache=yes
      CacheFromLocalhost=no
      DNSStubListener=yes
      ReadEtcHosts=yes
    '';
  };

  # Disable wait-online services for faster boot
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
}
