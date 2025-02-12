{pkgs ? import <nixpkgs> { }, ...}: rec {

  # gitkraken = pkgs.callPackage ./gitkraken { };
  # shellcolord = pkgs.callPackage ./shellcolord { };

  nix-inspect = pkgs.callPackage ./nix-inspect {};
  # wallpapers = pkgs.callPackage ./wallpapers { };
  f1multiviewer = pkgs.callPackage ./multiviewer {};

  # My wallpaper collection
  wallpapers = import ./wallpapers {inherit pkgs;};
  allWallpapers = pkgs.linkFarmFromDrvs "wallpapers" (pkgs.lib.attrValues wallpapers);

    # And colorschemes based on it
  generateColorscheme = import ./colorschemes/generator.nix {inherit pkgs;};
  colorschemes = import ./colorschemes {inherit pkgs wallpapers generateColorscheme;};
  allColorschemes = let
    # This is here to help us keep IFD cached (hopefully)
    combined = pkgs.writeText "colorschemes.json" (builtins.toJSON (pkgs.lib.mapAttrs (_: drv: drv.imported) colorschemes));
  in
    pkgs.linkFarmFromDrvs "colorschemes" (pkgs.lib.attrValues colorschemes ++ [combined]);
}
