{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    dnsutils # `dig` + `nslookup`
    ngrep
    nload
    nmap # A utility for network discovery and security auditing
    openresolv # a resolv.conf management framework
    rathole # similar to ngrok - NAT traversal and reverse proxy
    tcpdump
    # wgnord
    wireguard-tools
  ];
}
