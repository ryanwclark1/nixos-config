# Nix configuration modules
# This file imports all Nix-related configuration modules
{
  imports = [
    # Core Nix settings including garbage collection
    ./nix.nix

    # nh (Nix Helper) for flake-aware operations and cleanup
    ./nh.nix

    # nix-ld for running unpatched binaries
    ./nix-ld.nix
  ];
}
