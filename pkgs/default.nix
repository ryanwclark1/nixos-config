{pkgs ? import <nixpkgs> { }, ...}:

rec {

  # windsurf = pkgs.callPackage ./windsurf {inherit pkgs;};
  colors = pkgs.callPackage ./colors { };
  kiro = pkgs.callPackage ./kiro { };


}
