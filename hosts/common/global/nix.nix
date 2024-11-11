{
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;
    settings = {
      auto-optimise-store = true;
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 40;
      log-lines = 25;
      min-free = 128000000; # 128MB
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