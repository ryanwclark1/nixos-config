{
  lib,
  ...
}:

{
  programs = {
    mtr.enable = lib.mkDefault true;
  };
}
