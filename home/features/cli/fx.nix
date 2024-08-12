{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    fx # Terminal JSON viewer
  ];
}