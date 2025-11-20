{
  inputs,
  pkgs,
  ...
}:

{
  # Install hyprsunset from flake input
  home.packages = [ inputs.hyprsunset.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Copy hyprsunset configuration file
  home.file.".config/hypr/hyprsunset.conf".source = ./hyprsunset.conf;
}
