{
  lib,
  stdenvNoCC,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-colors";
  version = "1.0.0";

  src = ../../home/theme;

  installPhase = ''
    mkdir -p $out/share/colors
    cp colors.nix $out/share/colors/catppuccin.nix
    cp fonts.nix $out/share/colors/fonts.nix
  '';

  meta = with lib; {
    description = "Catppuccin color scheme";
    homepage = "https://github.com/catppuccin/catppuccin";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
