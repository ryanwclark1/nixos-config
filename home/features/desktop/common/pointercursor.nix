{
  lib,
  pkgs,
}:


# Look into hyprcursor
{
  pointerCursor = {
    package = lib.mkDefault pkgs.bibata-cursors;
    name = lib.mkDefault "Bibata-Modern-Classic";
    size = lib.mkDefault 16;
  };
}