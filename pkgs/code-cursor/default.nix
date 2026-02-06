{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  appimageTools,
  undmg,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
  # Get all build dependencies needed by generic.nix
  coreutils,
  gnugrep,
  copyDesktopItems,
  makeDesktopItem,
  unzip,
  libsecret,
  buildPackages,
  at-spi2-atk,
  autoPatchelfHook,
  buildFHSEnv,
  alsa-lib,
  libgbm,
  nss,
  nspr,
  libxrandr,
  libxfixes,
  libxext,
  libxdamage,
  libxcomposite,
  libx11,
  libxkbfile,
  libxcb,
  systemdLibs,
  fontconfig,
  imagemagick,
  libdbusmenu,
  glib,
  wayland,
  libglvnd,
  openssl,
  webkitgtk_4_1,
  ripgrep,
  asar,
  bash,
}:

let
  inherit (stdenv) hostPlatform;
  finalCommandLineArgs = "--update=false " + commandLineArgs;

  sourcesJson = lib.importJSON ./sources.json;
  inherit (sourcesJson) version vscodeVersion;
  sources = lib.mapAttrs (
    _: info:
    fetchurl {
      inherit (info) url hash;
    }
  ) sourcesJson.sources;

  source = sources.${hostPlatform.system};
  pname = "cursor";

  # Import the generic function
  genericFunction = import ../vscode-generic/generic.nix;

  # Call the function directly with explicit arguments to avoid callPackage auto-filling meta
  # First argument set: build dependencies
  # Second argument set: package-specific arguments
in
(genericFunction {
  inherit stdenv lib coreutils gnugrep copyDesktopItems makeDesktopItem unzip libsecret;
  inherit buildPackages at-spi2-atk autoPatchelfHook buildFHSEnv;
  inherit alsa-lib libgbm nss nspr libxrandr libxfixes libxext libxdamage libxcomposite;
  inherit libx11 libxkbfile libxcb systemdLibs fontconfig imagemagick libdbusmenu;
  inherit glib wayland libglvnd openssl webkitgtk_4_1 ripgrep asar bash;
} {
  inherit useVSCodeRipgrep version vscodeVersion;
  commandLineArgs = finalCommandLineArgs;

  inherit pname;

  executableName = "cursor";
  longName = "Cursor";
  shortName = "cursor";
  libraryName = "cursor";
  iconName = "cursor";

  src =
    if hostPlatform.isLinux then
      appimageTools.extract {
        inherit pname version;
        src = source;
      }
    else
      source;

  sourceRoot =
    if hostPlatform.isLinux then "${pname}-${version}-extracted/usr/share/cursor" else "Cursor.app";

  tests = { };
  updateScript = ./update.sh;

  # Editing the `cursor` binary within the app bundle causes the bundle's signature
  # to be invalidated, which prevents launching starting with macOS Ventura, because Cursor is notarized.
  # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
  dontFixup = stdenv.hostPlatform.isDarwin;

  # Cursor has no wrapper script.
  patchVSCodePath = false;

  meta = {
    description = "AI-powered code editor built on vscode";
    homepage = "https://cursor.com";
    changelog = "https://cursor.com/changelog";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [
      sarahec
      aspauldingcode
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ]
    ++ lib.platforms.darwin;
    mainProgram = "cursor";
  };
}).overrideAttrs
  (oldAttrs: {
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [ ]) ++ lib.optionals hostPlatform.isDarwin [ undmg ];

    passthru = (oldAttrs.passthru or { }) // {
      inherit sources;
    };
  })
