{
  services.nginx.virtualHosts = {
    "merope.techcasa.io" = {
      forceSSL = true;
      enableACME = true;
      locations."/".root = "/srv/files";
    };
  };
}
