{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    mtr # A network diagnostic tool
    iperf3
    ethtool # A utility for controlling network drivers and hardware
    socat # replacement of openbsd-netcat
  ];
}
