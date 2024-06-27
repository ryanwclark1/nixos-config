{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    blender-hip # Includes blender and thumbnailer
  ];
}
