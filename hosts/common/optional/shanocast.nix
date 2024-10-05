{ config, pkgs, ... }:

let
  shanocast = pkgs.callPackage ../../../pkgs/shanocast.nix {};
in
{
  environment.systemPackages = [
    shanocast
  ];
}