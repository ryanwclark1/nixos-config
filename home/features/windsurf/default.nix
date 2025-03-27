{ pkgs, ... }:

{
  home.packages = [
    (import ../../../pkgs/windsurf {
      inherit (pkgs) lib stdenv callPackage fetchurl nixosTests;
      commandLineArgs = "";
    })
  ];
}
