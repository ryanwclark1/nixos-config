{
  pkgs,
  ...
}:

{
  services.trayscale = {
    enable = true;
    package = pkgs.trayscale;
    hideWindow = true;
  };
}