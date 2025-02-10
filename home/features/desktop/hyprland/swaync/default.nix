{
  pkgs,
  ...
}:



{
  home.file.".config/swaync/config.json" = {
    source = ./config.json;
  };

  home.file.".config/swaync.style.css" = {
    source = ./style.css;
  };

  services.swaync = {
    enable = true;
    package = pkgs.swaync;
  };
}