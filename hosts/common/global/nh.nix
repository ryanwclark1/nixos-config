# nh, yet another Nix CLI helper
{
  pkgs,
  ...
}:


{
  programs.nh = {
    enable = true;
    package = pkgs.nh;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 4d --keep 3";
    };
    flake = "/home/administrator/nixos-config";
  };
}