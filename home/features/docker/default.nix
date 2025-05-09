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
}
