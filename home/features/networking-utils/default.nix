{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    dnsutils # `dig` + `nslookup`
    ngrep # Network packet analyzer.
    sngrep # CLI tool for visualizing SIP messages in a terminal UI
    nload # Monitors network traffic and bandwidth usage with ncurses graphs.
    nmap # A utility for network discovery and security auditing
    openresolv # a resolv.conf management framework
    # rathole # similar to ngrok - NAT traversal and reverse proxy
    tcpdump # Network sniffer
    wireguard-tools # Supplies the main userspace tooling for using and configuring WireGuard tunnels, including the wg(8) and wg-quick(8) utilities.
    netscanner # A simple network scanner
    mtr # A network diagnostic tool
    iperf # Tool to measure IP bandwidth using UDP or TCP.
    socat # replacement of openbsd-netcat
  ] ++ (if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then [
    ethtool # A utility for controlling network drivers and hardware
  ] else []);


}
