{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  gtk3,
  libdrm,
  xorg,
  mesa,
  nspr,
  nss,
  xdg-utils,
}:

stdenv.mkDerivation rec {
  pname = "antigravity";
  version = "1.11.2"; # matches current binary release

  # Upstream binary tarball (from AUR metadata)
  # https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.11.2-6251250307170304/linux-x64/Antigravity.tar.gz
  src = fetchurl {
    url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}-6251250307170304/linux-x64/Antigravity.tar.gz";
    # Build will fail with the correct hash - copy it from the error message
    sha256 = "sha256-0bERWudsJ1w3bqZg4eTS3CDrPnLWogawllBblEpfZLc=";
  };

  # Leave the root as-is so we see `Antigravity/` after unpack
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # Runtime deps (mirrors AUR deps as much as makes sense on Nix)
  buildInputs = [
    alsa-lib
    at-spi2-core
    gtk3
    libdrm
    xorg.libXScrnSaver
    xorg.libXtst
    mesa
    nspr
    nss
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/opt/antigravity
        mkdir -p $out/bin
        mkdir -p $out/share/applications
        mkdir -p $out/share/icons/hicolor/512x512/apps

        # After unpack, upstream layout is Antigravity/...
        cp -r Antigravity/* $out/opt/antigravity/

        # Main launcher wrapper
        makeWrapper "$out/opt/antigravity/antigravity" "$out/bin/antigravity" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
          --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"

        # Icon – matches what the AUR comments reference (VSCode-style icon)
        if [ -f Antigravity/resources/app/resources/linux/code.png ]; then
          install -Dm644 Antigravity/resources/app/resources/linux/code.png \
            "$out/share/icons/hicolor/512x512/apps/antigravity.png"
        fi

        # Desktop entry (includes custom URL scheme used for OAuth callback)
        cat > "$out/share/applications/antigravity.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=Antigravity
    Comment=Google Antigravity – Agentic Development IDE
    Icon=antigravity
    Categories=Development;IDE;
    StartupWMClass=Antigravity
    MimeType=x-scheme-handler/antigravity;
    X-KDE-Protocols=antigravity;
    Exec=$out/bin/antigravity %U
    Terminal=false
    EOF

        runHook postInstall
  '';

  meta = with lib; {
    description = "Google Antigravity – VS Code–based agentic development IDE";
    homepage = "https://antigravity.google/";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "antigravity";
  };
}
