{
  pkgs,
  ...
}:

{
  # Install hypridle package
  home.packages = [ pkgs.hypridle ];
  
  # Copy hypridle configuration file
  home.file.".config/hypr/hypridle.conf".source = ./hypridle.conf;
}