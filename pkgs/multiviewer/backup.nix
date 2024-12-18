{
  lib,
  stdenv,
  fetchzip,
  alsa-lib,
  gtk3,
  xdg-utils,
  copyDesktopItems,
  makeDesktopItem,
  unzip
}:

with lib;

let
  pname = "multiviewer";
  version = "1.34.0";

  throwSystem = throw "Unsupported system: ${stdenv.hostPlatform.system}";

  srcs = {
    x86_64-linux = fetchzip {
      url = "https://releases.multiviewer.app/download/155444733/MultiViewer.for.F1-linux-x64-${version}.zip";
      stripRoot = false;
      hash = "sha256-FHwbzLPMzIpyg6KyYTq6/rSNRH76dytwb9D5f9vNKkU=";
    };

    x86_64-darwin = fetchzip {
      url = "https://releases.multiviewer.app/download/155446334/MultiViewer.for.F1-1.31.5-x64.dmg";
      hash = "";
    };

    aarch64-darwin = fetchzip {
      url = "https://releases.multiviewer.app/download/155444823/MultiViewer.for.F1-1.31.5-arm64.dmg";
      hash = "";
    };
  };

  src = srcs.${stdenv.hostPlatform.system} or throwSystem;

  meta = with lib; {
    description = "Unofficial motorsports desktop client";
    homepage = "https://multiviewer.app";
    license = licenses.unknown; # Licenses in the dist apply to Electron, not f1multiviewer
    platforms = platforms.linux;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    maintainers = with maintainers; [ XXXXXXXXX ];
    mainProgram = "f1multiviewer";
  };

  linux = stdenv.mkDerivation rec {
    inherit pname version src meta;

    # at-spi2-core is included in aur build but is service not package in nixpkgs
    desktopItems = [
      (makeDesktopItem {
        name = "MultiViewer for F1";
        exec = "multiviewer %U";
        tryExec = "multiviewer";
        icon = "multiviewer";
        desktopName = "multiviewer";
        mimeTypes = [ "x-scheme-handler/multiviewer" "x-scheme-handler/multiviewer" ];
        comment = "Unofficial motorsports desktop client";
        categories = [ "AudioVideo" "Video" "TV" ];
      })
    ];

    nativeBuildInputs = [
      copyDesktopItems
      makeWrapper
      wrapGAppsHook
    ];

    buildInputs = [
      alsa-lib
      gtk3
      xdg-utils
      unzip
    ];

    # avoid double-wrapping
    # dontWrapGApps = true;

    # As taken from https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=f1multiviewer-bin
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/opt/${pname}
      cp -a "MultiViewer for F1-linux-x64/." "$out/opt/${pname}"

      install -d "$out/usr/bin/"
      ln -s "/opt/${pname}/MultiViewer for F1" "$out/usr/bin/${pname}"
      install -Dm644 "MultiViewer for F1-linux-x64/resources/app/.webpack/main/88a36af69fdc182ce561a66de78de7b1.png" "$out/usr/share/pixmaps/${pname}.png"
      install -Dm644 ${pname}.desktop "$out/usr/share/applications/${pname}.desktop"

      install -Dm644 "MultiViewer for F1-linux-x64/LICENSE" "$out/usr/share/licenses/${pname}/Electron-LICENSE"
      install -Dm644 "MultiViewer for F1-linux-x64/LICENSES.chromium.html" "$out/usr/share/licenses/${pname}/LICENSES.chromium.html"
      runHook postInstall
    '';
  };

  darwin = stdenv.mkDerivation {
    inherit pname version src meta;

    # No Clue
    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications/MultiViewer.app
      cp -R . $out/Applications/MultiViewer.app

      runHook postInstall
    '';

    dontFixup = true;
  };
in
if stdenv.isDarwin
then darwin
else linux
