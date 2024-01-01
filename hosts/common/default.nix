{
  config,
  pkgs,
  ...
}:

{
  imports = [
    # ./global/auto-upgrade.nix
    ./global/docker.nix
    ./global/locale.nix
    ./global/nfs.nix
    ./global/printing.nix
    ./global/fonts.nix
    ./global/users.nix
    ./global/virtualisation.nix
  ];
}