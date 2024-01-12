{ lib, config, ... }: {
  services = {
    navidrome = {
      enable = true;
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        MusicFolder = "/media/music";
        CovertArtPriority = "*.jpg, *.JPG, *.png, *.PNG, embedded";
        AutoImportPlaylists = false;
        EnableSharing = true;
      };
    };

    nginx.virtualHosts = {
      "music.techcasa.io" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass =
          "http://localhost:${toString config.services.navidrome.settings.Port}";
      };
      "music.techcasa.io" = {
        forceSSL = true;
        enableACME = true;
        locations."/".return = "302 https://music.techcasa.io$request_uri";
      };
    };
  };

  environment.persistence = {
    "/persist".directories = [ "/var/lib/private/navidrome" ];
  };
}
