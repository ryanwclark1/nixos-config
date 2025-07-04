{
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;

    # Automatic Nix garbage collection (DISABLED - using nh instead)
    # nh provides better flake-aware cleanup, so we disable the built-in GC
    # to avoid conflicts and use nh's more targeted approach
    gc = {
      automatic = false; # Disabled in favor of nh
      # dates = "weekly";
      # options = "--delete-older-than 30d";
    };

    settings = {
      auto-optimise-store = true;
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 134217728; # 128MB
      max-free = 1000000000; # 1GB
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
  };
}
