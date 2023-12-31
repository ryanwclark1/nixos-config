{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./global/auto-upgrade.nix
    ./global/docker.nix
    ./global/local.nix
    ./global/nfs.nix
    ./global/fonts.nix
  ];
}