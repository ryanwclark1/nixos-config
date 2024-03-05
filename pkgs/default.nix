{ pkgs ? import <nixpkgs> { } }: rec {

  # Packages with an actual source
  # shellcolord = pkgs.callPackage ./shellcolord { };
  # trekscii = pkgs.callPackage ./trekscii { };

  # Personal scripts
  # nix-inspect = pkgs.callPackage ./nix-inspect { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };
  xpo = pkgs.callPackage ./xpo { };
  # tly = pkgs.callPackage ./tly { };
  hyprslurp = pkgs.callPackage ./hyprslurp { };

  # My wallpaper collection
  # wallpapers = pkgs.callPackage ./wallpapers { };
}
