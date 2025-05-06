{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    bluez
    bluetui
  ];
}


