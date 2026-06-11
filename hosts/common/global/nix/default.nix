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
      # dates = "daily";
      # options = "--delete-older-than 3d";
    };

    settings = {
      auto-optimise-store = true;
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 1073741824; # 1GB
      max-free = 5368709120; # 5GB
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
        dates = "daily";
        extraArgs = "--keep-since 3d --keep 5";
      };

      flake = "/home/administrator/nixos-config";
    };

    nix-ld.enable = true;
  };
}
