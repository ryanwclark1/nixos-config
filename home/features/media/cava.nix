{
  pkgs,
  ...
}:

{
  programs.cava = {
    enable = true;
    package = pkgs.cava;
    # settings = {};
  };
}