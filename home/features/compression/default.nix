{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ouch
    p7zip # needed for 7z files
    zip
    unzip
    rar
  ];
}
