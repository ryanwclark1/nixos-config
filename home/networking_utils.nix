{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.networking_utils.enable = mkEnableOption "networking utilities settings";

  config = mkIf config.networking_utils.enable {
    home.packages = with pkgs; [
      mtr # A network diagnostic tool
      iperf3
      dnsutils  # `dig` + `nslookup`
      ldns # replacement of `dig`, it provide the command `drill`
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      socat # replacement of openbsd-netcat
      nmap # A utility for network discovery and security auditing
      ipcalc  # it is a calculator for the IPv4/v6 addresses
      wireguard-tools
      sniffnet
      libpcap
      tcpdump
      ngrep
      wireshark
      kubeshark
    ];
  };
}