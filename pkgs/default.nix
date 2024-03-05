{ pkgs ? import <nixpkgs> { } }: {

  gitkraken = pkgs.callPackage ./gitkraken { };
  # shellcolord = pkgs.callPackage ./shellcolord { };

  nix-inspect = pkgs.callPackage ./nix-inspect { };
  # wallpapers = pkgs.callPackage ./wallpapers { };
}
