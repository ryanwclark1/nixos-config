{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    blueman
    bluez
    bluetui
  ];
}


