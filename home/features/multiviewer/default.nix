{
  pkgs,
  ...
}:
let
  updatedId = "237882044";  # New ID
  updatedVersion = "1.42.1";  # New version
  updatedSha256 = "1qflnw12r9da9rgx2i1l9j2scj10s9ig46ak36395x73pp9y4gca";  # New SHA256
in
{
  # nixpkgs.overlays = [
  #   (
  #     final: prev: {
  #       multiviewer-for-f1  = prev.multiviewer-for-f1.overrideAttrs (_: rec {
  #         version = "updatedVersion";

  #         src = pkgs.fetchurl {
  #           url = "https://releases.multiviewer.dev/download/${updatedId}/multiviewer-for-f1_${updatedVersion}_amd64.deb";
  #           sha256 = updatedSha256;
  #         };
  #       });
  #     }
  #   )
  # ];

  home.packages = [
    pkgs.multiviewer-for-f1
  ];
}
