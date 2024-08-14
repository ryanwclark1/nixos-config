{
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = lib.mkDefault pkgs.nix;

    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
      ];
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      # Keep the last 5 generations
      options = "--delete-older-than +5";
    };
  };
}