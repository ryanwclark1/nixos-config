{
  lib,
  pkgs,
  ...
}:

{
  home.pointerCursor = {
    enable = true;
    hyprcursor = {
      enable = true;
      size = 22;
    };
    package = lib.mkDefault pkgs.bibata-cursors;
    name = lib.mkDefault "Bibata-Modern-Classic";
    size = lib.mkDefault 22;
  };
}
