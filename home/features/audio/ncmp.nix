{
  pkgs,
  ...
}:

{
  programs.ncmpcpp = {
    package = pkgs.ncmpcpp.override { visualizerSupport = true; };
    enable = true;
  };
}
