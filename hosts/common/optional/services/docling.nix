{
  config,
  lib,
  pkgs,
  ...
}:

{


  services.docling-serve = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    port = 5051;
    environment = {
      DOCLING_SERVE_ENABLE_UI = "true";
    };
  };
}
