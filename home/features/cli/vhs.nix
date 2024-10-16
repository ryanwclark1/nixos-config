
# A tool for generating terminal GIFs with code
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    vhs
  ];
}
