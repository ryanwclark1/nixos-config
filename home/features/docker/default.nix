{
  pkgs,
  ...
}:

# Docker needs to be enabled at the host/system level
{
  home.packages = with pkgs; [
    lazydocker # A simple terminal UI for both docker and docker
    dive # A tool for exploring each layer in a docker image.dive
  ];

  # Ensure Docker CLI can find Buildx and Compose even when PATH is overridden
  # Docker searches ~/.docker/cli-plugins for CLI plugins
  home.file.".docker/cli-plugins/docker-buildx".source = "${pkgs.docker-buildx}/bin/docker-buildx";
  home.file.".docker/cli-plugins/docker-compose".source = "${pkgs.docker-compose}/bin/docker-compose";
}
