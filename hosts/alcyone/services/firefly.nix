{ inputs, config, ... }:
{
  imports = [
    inputs.firefly.nixosModules.firefly-iii
  ];

  nixpkgs.overlays = [ inputs.firefly.overlays.default ];

  services.firefly-iii = {
    enable = true;
    hostname = "firefly.techcasa.io";
    appKeyFile = config.sops.secrets.firefly-key.path;
    nginx = {
      serverAliases = [ "firefly.techcasa.io" ];
      forceSSL = true;
      enableACME = true;
    };
    group = "nginx";
    database.createLocally = true;
  };

  sops.secrets.firefly-key = {
    owner = "firefly-iii";
    group = "nginx";
    sopsFile = ../secrets.yaml;
  };

  environment.persistence = {
    "/persist".directories = [ "/var/lib/firefly-iii" ];
  };
}
