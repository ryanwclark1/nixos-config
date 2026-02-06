{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  jq,
  buildFHSEnv,
  writeShellScript,
  coreutils,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
  # Get all build dependencies needed by generic.nix
  gnugrep,
  copyDesktopItems,
  makeDesktopItem,
  unzip,
  libsecret,
  buildPackages,
  at-spi2-atk,
  autoPatchelfHook,
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
  information = (lib.importJSON ./information.json);
  source =
    information.sources."${hostPlatform.system}"
      or (throw "antigravity: unsupported system ${hostPlatform.system}");

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
  inherit commandLineArgs useVSCodeRipgrep;
  inherit (information) version vscodeVersion;
  pname = "antigravity";

  executableName = "antigravity";
  longName = "Antigravity";
  shortName = "Antigravity";
  libraryName = "antigravity";
  iconName = "antigravity";

  src = fetchurl { inherit (source) url sha256; };

  sourceRoot = if hostPlatform.isDarwin then "Antigravity.app" else "Antigravity";

  # When running inside an FHS environment, try linking Google Chrome or Chromium
  # to the hardcoded Playwright search path: /opt/google/chrome/chrome
  customizeFHSEnv =
    args:
    buildFHSEnv (
      args
      // {
        extraBuildCommands = (args.extraBuildCommands or "") + ''
          mkdir -p "$out/opt/google/chrome"
        '';
        extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [ "--tmpfs /opt/google/chrome" ];
        runScript = writeShellScript "antigravity-wrapper" ''
          for candidate in google-chrome-stable google-chrome chromium-browser chromium; do
            if target=$(command -v "$candidate"); then
              ${coreutils}/bin/ln -sf "$target" /opt/google/chrome/chrome
              break
            fi
          done
          exec ${args.runScript} "$@"
        '';
      }
    );

  tests = { };
  updateScript = ./update.sh;

  meta = {
    mainProgram = "antigravity";
    description = "Agentic development platform, evolving the IDE into the agent-first era";
    homepage = "https://antigravity.google";
    downloadPage = "https://antigravity.google/download";
    changelog = "https://antigravity.google/changelog";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with lib.maintainers; [
      xiaoxiangmoe
      Zaczero
    ];
  };
}).overrideAttrs
  (oldAttrs: {
    # Disable update checks
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ jq ];
    postPatch = (oldAttrs.postPatch or "") + ''
      productJson="${
        if stdenv.hostPlatform.isDarwin then "Contents/Resources" else "resources"
      }/app/product.json"
      data=$(jq 'del(.updateUrl)' "$productJson")
      echo "$data" > "$productJson"
    '';
  })
