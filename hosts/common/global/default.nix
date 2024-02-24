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
    ./locale.nix
    # ./networking.nix
    ./nix.nix
    ./openssh.nix
    ./sops.nix
    ./systemd-initrd.nix
    # ./ssh-serve-store.nix
    ./tailscale.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nixpkgs = {
    # overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };


  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = [ "/lib/qt-6/plugins" ];
  };

  hardware.enableRedistributableFirmware = true;
  networking.domain = "techcasa.io";

}
