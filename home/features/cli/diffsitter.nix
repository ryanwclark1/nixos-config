{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    diffsitter # Better diff
  ];
}