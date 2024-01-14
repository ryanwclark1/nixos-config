{ pkgs, lib, ... }: {
  home.packages = [ pkgs.prismlauncher-qt5 ];

  # home.persistence = {
  #   "/persist/home/administrator".directories = [ ".local/share/PrismLauncher" ];
  # };
}
