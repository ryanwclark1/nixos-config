{
  pkgs,
  ...
}:

{
  services.cliphist = {
    enable = true;
    package = pkgs.cliphist;
    allowImages = true;
  };
}