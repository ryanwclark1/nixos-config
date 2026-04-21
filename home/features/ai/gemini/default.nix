{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = [ pkgs.gemini-cli ];
}
