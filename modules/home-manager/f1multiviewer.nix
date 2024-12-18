{ lib
, stdenv
, fetchurl
, makeWrapper
, electron
, writeShellScript
, nss
, alsaLib
, gtk3
, at-spi2-core
, xdg-utils
}:

let
  pname = "f1multiviewer";
  version = "1.36.2";
  build = "203624822";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://releases.multiviewer.app/download/${build}/MultiViewer.for.F1-linux-x64-${version}.zip";
    sha256 = "2508aaeb29f92c9ddc3c8d242cdd5a82f48172bd532b1ed62e48cff3354dc66e";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    nss
    alsaLib
    gtk3
    at-spi2-core
    xdg-utils
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/f1multiviewer
    cp -r ./* $out/opt/f1multiviewer/

    # Create desktop entry
    mkdir -p $out/share/applications
    cat > $out/share/applications/f1multiviewer.desktop << EOF
    [Desktop Entry]
    Name=MultiViewer for F1
    Exec=$out/bin/f1multiviewer
    Icon=$out/share/pixmaps/f1multiviewer.png
    Type=Application
    Categories=AudioVideo;
    EOF

    # Install icon
    mkdir -p $out/share/pixmaps
    cp resources/app/.webpack/main/88a36af69fdc182ce561a66de78de7b1.png $out/share/pixmaps/f1multiviewer.png

    # Create wrapper script
    mkdir -p $out/bin
    makeWrapper "$out/opt/f1multiviewer/MultiViewer for F1" $out/bin/f1multiviewer \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

    # Install license files
    mkdir -p $out/share/licenses/f1multiviewer
    cp LICENSE $out/share/licenses/f1multiviewer/Electron-LICENSE
    cp LICENSES.chromium.html $out/share/licenses/f1multiviewer/LICENSES.chromium.html

    runHook postInstall
  '';

  meta = with lib; {
    description = "Unofficial motorsports desktop client";
    homepage = "https://multiviewer.app";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ ];
  };
}