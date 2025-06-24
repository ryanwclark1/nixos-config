# This file (and the global directory) holds config that i use on all hosts
{
  inputs,
  outputs,
  ...
}:

{
  imports = [
    # Core system modules
    ./core

    # Networking
    ./networking

    # Security
    ./security

    # Nix ecosystem
    ./nix

    # Performance tuning
    ./performance

    # Virtualisation
    ./virtualisation

    # Monitoring
    ./monitoring

    # Configuration validation
    ./validation

    # Secrets management
    ./sops.nix

    # Home manager
    inputs.home-manager.nixosModules.home-manager
  ];

  # Global settings
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfree = true;
  };

  networking.domain = "techcasa.io";
}
