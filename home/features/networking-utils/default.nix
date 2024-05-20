{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    dnsutils # `dig` + `nslookup`
    ipcalc # it is a calculator for the IPv4/v6 addresses
    ldns # replacement of `dig`, it provide the command `drill`
    libpcap
    ngrep
    nmap # A utility for network discovery and security auditing
    openresolv # a resolv.conf management framework
    rathole # similar to ngrok - NAT traversal and reverse proxy
    tcpdump
    wgnord
    wireguard-tools
  ];
}
