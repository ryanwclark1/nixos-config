{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    p7zip # needed for 7z files
    zip
    rar
    pigz
    atool
    xz
    zstd
    zpaq
  ];
}
