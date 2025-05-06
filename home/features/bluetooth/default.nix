{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    bluetoothz
    bluetui
  ];
}


