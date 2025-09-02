# nh, yet another Nix CLI helper
# nh provides flake-aware Nix operations and cleanup
{
  pkgs,
  ...
}:

{
  programs.nh = {
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
      extraArgs = "--keep-since 10d --keep 15";
    };

    # Point nh to your flake configuration
    flake = "/home/administrator/nixos-config";
  };
}
