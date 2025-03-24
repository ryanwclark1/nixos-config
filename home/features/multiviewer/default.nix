{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    multiviewer-for-f1
  ];
}
