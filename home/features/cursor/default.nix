{ pkgs, ... }:

{
  home.packages = [
    (import ../../../pkgs/code-cursor {
      inherit (pkgs) lib stdenvNoCC fetchurl appimageTools makeWrapper writeScript undmg;
    })
  ];
}
