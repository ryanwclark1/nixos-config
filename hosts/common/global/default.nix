# This file (and the global directory) holds config that i use on all hosts
{
  inputs,
  outputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    # ./auto-upgrade.nix
    ./fish.nix
    ./fonts.nix
    ./gamemode.nix
    ./locale.nix
    ./networking.nix
    ./nfs.nix
    ./nix.nix
    ./openssh.nix
    ./sops.nix
    # ./ssh-serve-store.nix
    ./steam-hardware.nix
    ./systemd-boot.nix
    ./tailscale.nix
    ./zsh.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nixpkgs = {
    # overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  # Fix for qt6 plugins
  # TODO: maybe upstream this?
  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = [ "/lib/qt-6/plugins" ];
  };

  hardware.enableRedistributableFirmware = true;
  networking.domain = "techcasa.io";

}
