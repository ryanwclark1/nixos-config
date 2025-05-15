# Borrowed from vimjoyeer

{
  pkgs,
  ...
}:
let
  image = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Goxore/dotfiles/50db864d56d49768f1d4d0a8c1bd7a5c74dd629e/home/Wallpapers/gruvbox-mountain-village.png";
    sha256 = "sha256-HrcYriKliK2QN02/2vFK/osFjTT1NamhGKik3tozGU0=";
  };
in
pkgs.stdenv.mkDerivation {
  name = "sddm-astronaut-theme";

  src = pkgs.fetchFromGitHub {
    owner = "Keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "bf4d01732084be29cedefe9815731700da865956";
    sha256 = "sha256-JMCG7oviLqwaymfgxzBkpCiNi18BUzPGvd3AF9BYSeo=";
  };
  installPhase = ''
    mkdir -p $out
    cp -R ./* $out/
    cd $out/
    if [ -f Background.jpg ]; then
      rm Background.jpg
    fi
    cp -r ${image} $out/Background.jpg
  '';
}
