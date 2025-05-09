{
  pkgs,
  ...
}:

{
  services.hyprpolkitagent = {
    enable = true;
    package = pkgs.hyprpolkitagent;
  };
}
