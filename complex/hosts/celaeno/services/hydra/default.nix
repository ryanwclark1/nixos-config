{ pkgs, lib, config, outputs, inputs, ... }:
let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;

  release-host-branch = pkgs.callPackage ./lib/release-host-branch.nix {
    sshKeyFile = config.sops.secrets.nix-ssh-key.path;
  };
in
{
  imports = [
    ./machines.nix
  ];

  # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  services = {
    hydra = {
      enable = true;
      hydraURL = "https://hydra.techcasa.io";
      notificationSender = "hydra@techcasa.io";
      listenHost = "localhost";
      smtpHost = "localhost";
      useSubstitutes = true;
      extraConfig = /* xml */ ''
        Include ${config.sops.secrets.hydra-gh-auth.path}
        max_unsupported_time = 30
        <githubstatus>
          jobs = .*
          useShortContext = true
        </githubstatus>
        <runcommand>
          job = nix-config:main:*
          command = ${lib.getExe release-host-branch}
        </runcommand>
      '';
      extraEnv = { HYDRA_DISALLOW_UNFREE = "0"; };
    };
    nginx.virtualHosts = {
      "hydra.techcasa.io" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "~* ^/shield/([^\\s]*)".return =
            "302 https://img.shields.io/endpoint?url=https://hydra.techcasa.io/$1/shield";
          "/".proxyPass =
            "http://localhost:${toString config.services.hydra.port}";
        };
      };
    };
  };
  users.users = {
    hydra-queue-runner.extraGroups = [ hydraGroup ];
    hydra-www.extraGroups = [ hydraGroup ];
  };
  sops.secrets = {
    hydra-gh-auth = {
      sopsFile = ../../secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0440";
    };
    nix-ssh-key = {
      sopsFile = ../../secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0440";
    };
  };

  # environment.persistence = {
  #   "/persist".directories = [ "/var/lib/hydra" ];
  # };
}
