{
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = lib.mkDefault pkgs.nixVersions.git;

    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
      ];
      warn-dirty = false;
      system-features = [
        "kvm"
        "big-parallel"
        "nixos-test"
      ];

    };

    gc = {
      automatic = true;
      # Keep the last 14 days of generations
      options = "--delete-older-than 30d";
    };
  };
}