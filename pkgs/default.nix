{ pkgs ? import <nixpkgs> { } }: {
  gitkraken = pkgs.callPackage ./gitkraken { };
  # wallpapers = pkgs.callPackage ./wallpapers { };
}
