# This file (and the global directory) holds config that i use on all hosts
{
  inputs,
  outputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./fail2ban.nix
    ./locale.nix
    ./networking.nix
    ./nh.nix
    ./nix.nix
    ./nix-ld.nix
    ./openssh.nix
    ./sops-config.nix
    ./system.nix
    ./boot.nix
    ./security.nix
  ]; # ++ (builtins.attrValues outputs.nixosModules);

  # home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  # allowUnfree isn't being inherited from the global flake
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  networking.domain = "techcasa.io";
}
