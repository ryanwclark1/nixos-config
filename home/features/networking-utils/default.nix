{
  pkgs,
  lib,
  config,
  ...
}:

{
  home.packages = with pkgs; [
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    ethtool # A utility for controlling network drivers and hardware
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    wireguard-tools
    libpcap
    tcpdump
    rathole # similar to ngrok - NAT traversal and reverse proxy

    ngrep
    wireshark
    kubeshark
  ];
}