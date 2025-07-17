{
  ...
}:

{
  services.docling-serve = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    port = 5001;
    environment = {
      DOCLING_SERVE_ENABLE_UI = "True";
    };

  };
}
