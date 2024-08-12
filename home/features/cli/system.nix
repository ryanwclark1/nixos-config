{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    mprocs # multiple commands in parallel
    pciutils # lspci
    usbutils # lsusb
  ];
}