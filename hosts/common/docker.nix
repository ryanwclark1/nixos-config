# ./host/common/global/docker.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;

{
  options.docker.enable = mkEnableOption "docker settings";

  config = mkIf config.docker.enable {
    virtualisation = {
      docker = {
        enable = true;
        listenOptions = ["/run/docker.sock"];
        enableOnBoot = true;
        # enableNvidia = true;
        logDriver = "journald";

        autoPrune = {
          enable = true;
          flags = ["--all"];
          dates = "weekly";
        };
      };
    };
  };
}