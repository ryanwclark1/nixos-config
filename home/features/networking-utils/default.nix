{ pkgs
, ...
}:

{
  home.packages = with pkgs; [

    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility


    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses
    wireguard-tools
    libpcap
    tcpdump
    rathole # similar to ngrok - NAT traversal and reverse proxy
    ngrep
    wireshark

  ];
}
