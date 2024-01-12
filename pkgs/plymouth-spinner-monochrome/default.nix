{ stdenv, logo ? null, lib, ... }: stdenv.mkDerivation {
  pname = "plymouth-spinner-monochrome";
  version = "1.0";
  src = ./src;

  installPhase = ''
    mkdir -p $out/share/plymouth/themes
    cp -rT $src $out/share/plymouth/themes/spinner-monochrome
  '' + (lib.optionalString (logo != null) ''
    ln -s ${logo} $out/share/plymouth/themes/spinner-monochrome/watermark.png
  '');

  meta = {
    platforms = lib.platforms.all;
  };
}
