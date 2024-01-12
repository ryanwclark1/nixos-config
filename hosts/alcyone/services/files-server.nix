let
  files = {
    forceSSL = true;
    enableACME = true;
    locations."/".root = "/srv/files";
  };
in
{
  services.nginx.virtualHosts = {
    "files.techcasa.io" = files;
    "f.techcasa.io" = files;
  };
}
