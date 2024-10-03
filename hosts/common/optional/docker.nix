{
  pkgs,
  ...
}:

{
  virtualisation = {
    docker = {
      enable = true;
      package = pkgs.docker;
      listenOptions = [
        "/var/run/docker.sock"
        "/run/docker.sock"
      ];
      enableOnBoot = true;
      logDriver = "journald";

      autoPrune = {
        enable = true;
        flags = [ "--all" ];
        dates = "weekly";
      };
    };
  };
}
