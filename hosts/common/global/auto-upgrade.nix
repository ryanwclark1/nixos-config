# ./host/common/global/auto-upgrade.nix
{
  config,
  # inputs,
  ...
}:

let
  inherit (config.networking) hostName;
  # Only enable auto upgrade if current config came from a clean tree
  # This avoids accidental auto-upgrades when working locally.
  isClean = inputs.self ? rev;
in
{
  system.autoUpgrade = {
    enable = isClean;
    dates = "hourly";
    flags = [
      "--refresh"
    ];
    flake = "git@github.com:ryanwclark1/nixos-config.git?ref=release-${hostName}";
  };
}