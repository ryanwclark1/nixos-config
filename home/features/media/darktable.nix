{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    darktable
  ];
}
