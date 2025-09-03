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

  programs = {
    nh = {
      enable = true;
      package = pkgs.nh;

      # nh clean configuration (user-level, flake-specific)
      # This runs as a user service and focuses on your specific flake
      # - More aggressive: keeps only 4 days of history + 3 generations
      # - Flake-specific scope: only affects your NixOS configuration
      # - Purpose: Quick rollbacks and flake-specific optimization
      # - Complementary to nix.gc: provides faster, more targeted cleanup
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 10d --keep 25";
      };

      # Point nh to your flake configuration
      flake = "/home/administrator/nixos-config";
    };

    nix-ld.enable = true;
  };
}
