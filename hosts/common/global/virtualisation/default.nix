{
  pkgs,
  ...
}:

{
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker;
    listenOptions = [
      "/var/run/docker.sock"
      "/run/docker.sock"
    ];
    enableOnBoot = true;
    logDriver = "journald";

    # Fix DNS resolution issues
    daemon.settings = {
      dns = [ "8.8.8.8" "1.1.1.1" ];
      dns-opts = [ "ndots:0" ];
      # Enable BuildKit engine for advanced builds and Buildx/Bake
      features = { buildkit = true; };
    };

    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "weekly";
    };
  };

  # Add Docker Buildx and Compose for advanced build features
  environment.systemPackages = with pkgs; [
    docker-buildx
    docker-compose
  ];
}
