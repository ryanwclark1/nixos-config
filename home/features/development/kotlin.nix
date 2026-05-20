{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    kotlin
    gradle
    jdk17
  ];
}
