{
  ...
}:

{
  imports = [
    # ./global/auto-upgrade.nix
    ./global/boot.nix
    ./global/docker.nix
    ./global/locale.nix
    ./global/nfs.nix
    ./global/pipewire.nix
    ./global/printing.nix
    ./global/fonts.nix
    ./global/users.nix
    ./global/virtualisation.nix
  ];
}