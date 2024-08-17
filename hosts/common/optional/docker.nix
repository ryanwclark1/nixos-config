{
  ...
}:

{
  virtualisation = {
    docker = {
      enable = true;
      listenOptions = [ "/run/docker.sock" ];
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
