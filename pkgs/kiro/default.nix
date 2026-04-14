{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  extraCommandLineArgs ? "",
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
  sources = (lib.importJSON ./sources.json).${stdenv.hostPlatform.system};

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
  inherit useVSCodeRipgrep;
  commandLineArgs = extraCommandLineArgs;

  version = "0.11.131";
  pname = "kiro";

  # You can find the current VSCode version in the About dialog:
  # workbench.action.showAboutDialog (Help: About)
  vscodeVersion = "1.107.1";

  executableName = "kiro";
  longName = "Kiro";
  shortName = "kiro";
  libraryName = "kiro";
  iconName = "kiro";

  src = fetchurl {
    url = sources.url;
    hash = sources.hash;
  };
  sourceRoot = "Kiro";
  patchVSCodePath = true;

  tests = { };
  updateScript = ./update.sh;

  meta = {
    description = "IDE for Agentic AI workflows based on VS Code";
    homepage = "https://kiro.dev";
    license = lib.licenses.amazonsl;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ vuks ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "kiro";
  };

}).overrideAttrs
  (oldAttrs: {
    passthru = (oldAttrs.passthru or { }) // {
      inherit sources;
    };
  })
