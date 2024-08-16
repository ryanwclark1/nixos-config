{
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;

    settings = {
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB

      auto-optimise-store = true;

      experimental-features = [
        "nix-command"
        "flakes"
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
      options = "--delete-older-than 10d";
    };
  };
}