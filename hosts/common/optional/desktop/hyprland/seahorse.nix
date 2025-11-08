{
  lib,
  ...
}:

{
  programs = {
    seahorse.enable = lib.mkDefault true;
  };
}
