{ pkgs, ... }:
let
  website = pkgs.inputs.website.default;
  pgpKey = ../../../../home/administrator/pgp.asc;
  sshKey = ../../../../home/administrator/ssh.pub;
  redir = {
    forceSSL = true;
    enableACME = true;
    locations."/".return = "302 https://techcasa.io$request_uri";
  };
  days = n: (hours n) * 24;
  hours = n: (minutes n) * 60;
  minutes = n: n * 60;
in
{
  imports = [ ./themes.nix ./shortner.nix ];

  services.nginx.virtualHosts = {
    "techcasa.io" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          root = "${website}/public";
          extraConfig = ''
            add_header Cache-Control "max-age=${toString (minutes 15)}";
          '';
        };
        "/assets/" = {
          root = "${website}/public";
          extraConfig = ''
            add_header Cache-Control "max-age=${toString (days 30)}";
          '';
        };

        "=/nix" = {
          # Script to download static nix
          alias = ./scripts/nix-installer.sh;
        };

        "=/setup-gpg" = {
          alias = ./scripts/setup-gpg.sh;
        };

        "=/7088C7421873E0DB97FF17C2245CAB70B4C225E9.asc".alias = pgpKey;
        "=/pgp.asc".alias = pgpKey;
        "=/pgp".alias = pgpKey;
        "=/ssh.pub".alias = sshKey;
        "=/ssh".alias = sshKey;
      };
    };
    "clarkfamily.com" = redir;
  };
}
