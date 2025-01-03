{
  pkgs,
  ...
}:

{
  services.thermald = {
    enable = true;
    package = pkgs.thermald;
  };
}