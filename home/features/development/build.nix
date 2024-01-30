# just is a handy way to save and run project-specific commands.
# Similar to make
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    cmake
    gnumake
    just
  ];
}