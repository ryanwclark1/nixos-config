# hosts/common/global/nix/default.nix
{
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;

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
      download-buffer-size = 536870912; # 128MB (default is 64MB)
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
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 10d --keep 25";
      };

      flake = "/home/administrator/nixos-config";
    };

    nix-ld.enable = true;
  };
}
