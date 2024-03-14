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
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./openssh.nix
    ./sops.nix
    # ./ssh-serve-store.nix
    ./tailscale.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

# allowUnfree isn't being inherited from the global flake
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };


}
