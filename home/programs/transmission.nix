 {
  config,
  pkgs,
  home-manager,
  ...
}:

{
  programs.transmission = {
    enable = true;
    settings = {
    };
  };
}