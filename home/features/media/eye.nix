{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    eog
  ];
}
