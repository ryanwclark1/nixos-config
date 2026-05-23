{
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    android-tools
  ] ++ lib.optionals stdenv.isLinux [
    android-studio
  ];
}
