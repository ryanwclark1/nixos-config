{
  pkgs,
  ...
}:

{
  hardware.keyboard.qmk.enable = true;
  
  environment.systemPackages = [
    pkgs.via
  ];
  
  services.udev.packages = [ 
    pkgs.via 
  ];
}