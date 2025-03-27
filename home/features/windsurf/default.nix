{ pkgs, ... }:

{
  home.packages = [
    (import ../../../pkgs/windsurf {
      inherit (pkgs) lib stdenv callPackage fetchurl;
      inherit (pkgs.nixos-testers) nixosTests;
      vscode-generic = pkgs.vscode-utils.vscode-generic;
    })
  ];
}
