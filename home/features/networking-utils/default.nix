{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # Cross-platform networking utilities
    bind.dnsutils # `dig` + `nslookup` - works on all platforms
    nmap # A utility for network discovery and security auditing - cross-platform
    tcpdump # Network sniffer - available on macOS
    wireguard-tools # WireGuard utilities - cross-platform
    mtr # A network diagnostic tool - cross-platform  
    iperf # Tool to measure IP bandwidth using UDP or TCP - cross-platform
    socat # replacement of openbsd-netcat - cross-platform
    # rathole # similar to ngrok - NAT traversal and reverse proxy
  ] ++ (if pkgs.stdenv.hostPlatform.isLinux then [
    # Linux-specific networking utilities
    inetutils # Basic networking utilities - Linux-focused implementation
    ngrep # Network packet analyzer - Linux-specific features
    sngrep # CLI tool for visualizing SIP messages - primarily Linux
    nload # Network traffic monitor with ncurses - Linux-specific
    openresolv # resolv.conf management framework - Linux-specific
    netscanner # Network scanner - Linux-specific
    ethtool # Ethernet hardware control - Linux kernel specific
  ] else []);

}
