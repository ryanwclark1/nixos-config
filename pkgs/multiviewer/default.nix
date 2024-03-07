{
  lib,
  stdenv,
  fetchzip,
  alsa-lib,
  gtk3,
  xdg-utils,
  copyDesktopItems,
  makeDesktopItem,
  zlib
}:
stdenv.mkDerivation {
  pname = "multiviewer";
  version = "1.31.5";

  src = fetchzip {
    url = "https://releases.multiviewer.app/download/155444733/MultiViewer.for.F1-linux-x64-1.31.5.zip";
    stripRoot = false;
    hash = "sha256-FHwbzLPMzIpyg6KyYTq6/rSNRH76dytwb9D5f9vNKkU=";
  };

  # at-spi2-core is included in aur build but is service not package in nixpkgs
  buildInputs = [
    alsa-lib
    gtk3
    xdg-utils
    zlib
  ];

  nativeBuildInputs = [ copyDesktopItems ];

  desktopItems = [
    (makeDesktopItem {
      name = "MultiViewer for F1";
      exec = "f1multiviewer %U";
      tryExec = "f1multiviewer";
      icon = "f1multiviewer";
      desktopName = "f1multiviewer";
      mimeTypes = [ "x-scheme-handler/multiviewer" "x-scheme-handler/multiviewer" ];
      comment = "Unofficial motorsports desktop client";
      categories = [ "AudioVideo" "Video" "TV" ];
    })
  ];

  # As taken from https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=f1multiviewer-bin
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/opt/f1multiviewer
    cp -a "MultiViewer for F1-linux-x64/." "$out/opt/f1multiviewer"

    install -d "$out/usr/bin/"
    ln -s "/opt/f1multiviewer/MultiViewer for F1" "$out/usr/bin/f1multiviewer"
    install -Dm644 "MultiViewer for F1-linux-x64/resources/app/.webpack/main/88a36af69fdc182ce561a66de78de7b1.png" "$out/usr/share/pixmaps/f1multiviewer.png"
    install -Dm644 f1multiviewer.desktop "$out/usr/share/applications/f1multiviewer.desktop"

    install -Dm644 "MultiViewer for F1-linux-x64/LICENSE" "$out/usr/share/licenses/f1multiviewer/Electron-LICENSE"
    install -Dm644 "MultiViewer for F1-linux-x64/LICENSES.chromium.html" "$out/usr/share/licenses/f1multiviewer/LICENSES.chromium.html"
    runHook postInstall
  '';


  meta = with lib; {
    description = "Unofficial motorsports desktop client";
    homepage = "https://multiviewer.app";
    license = licenses.unknown; # Licenses in the dist apply to Electron, not f1multiviewer
    platforms = platforms.linux;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    maintainers = with maintainers; [ ryanwclark1 ];
    mainProgram = "f1multiviewer";
  };
}