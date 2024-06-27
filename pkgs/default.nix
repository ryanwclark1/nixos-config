{ pkgs ? import <nixpkgs> { } }: {

  aichat = pkgs.callPackage ./aichat { };
  gitkraken = pkgs.callPackage ./gitkraken { };
  # shellcolord = pkgs.callPackage ./shellcolord { };

  nix-inspect = pkgs.callPackage ./nix-inspect { };
  # wallpapers = pkgs.callPackage ./wallpapers { };
  # multiviewer = pkgs.callPackage ./multiviewer { };
}
