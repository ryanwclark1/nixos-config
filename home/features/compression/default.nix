{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    atool
    p7zip # needed for 7z files
    zip
    unzip
    pigz
    rar
    zstd
    zpaq
  ];
}
