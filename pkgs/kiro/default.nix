{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  wrapGAppsHook,
  autoPatchelfHook,
  glib,
  nss,
  nspr,
  atk,
  at-spi2-atk,
  cups,
  dbus,
  libdrm,
  gtk3,
  pango,
  cairo,
  xorg,
  expat,
  libxkbcommon,
  alsa-lib,
  mesa,
  libGL,
  libnotify,
  libuuid,
  libsecret,
  systemd,
  gsettings-desktop-schemas,
}:

stdenv.mkDerivation rec {
  pname = "kiro";
  version = "0.1.6";
  
  src = fetchurl {
    url = "https://prod.download.desktop.kiro.dev/releases/202507152342--distro-linux-x64-tar-gz/202507152342-distro-linux-x64.tar.gz";
    sha256 = "1cp53q252yixrzkgspjhqfnnsldxs8sh5zidp276q2c4j70csykq";
  };
  
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook
  ];
  
  buildInputs = [
    stdenv.cc.cc.lib
    glib
    nss
    nspr
    atk
    at-spi2-atk
    cups
    dbus
    libdrm
    gtk3
    pango
    cairo
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    expat
    libxkbcommon
    alsa-lib
    mesa
    libGL
    libnotify
    libuuid
    libsecret
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libxkbfile
  ];
  
  sourceRoot = ".";
  
  dontWrapGApps = true;
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/opt
    cp -r Kiro $out/opt/
    
    chmod +x $out/opt/Kiro/kiro
    chmod +x $out/opt/Kiro/chrome_crashpad_handler
    
    mkdir -p $out/bin
    
    makeWrapper $out/opt/Kiro/kiro $out/bin/kiro \
      --add-flags "--no-sandbox" \
      --add-flags "--disable-gpu" \
      --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}" \
      --set GTK_THEME "Adwaita" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        systemd
        libGL
        mesa
      ]}"
    
    runHook postInstall
  '';
  
  passthru.updateScript = ./update.sh;
  
  meta = with lib; {
    description = "Kiro - AI-powered IDE by Amazon";
    homepage = "https://kiro.dev";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [];
  };
}