{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  jq,
  buildFHSEnv,
  writeShellScript,
  coreutils,
  gawk,
  getconf,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
  # Get all build dependencies needed by generic.nix
  gnugrep,
  gnused,
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
  which,
  asar,
  bash,
  # Playwright browsers for browser automation support
  # This ensures browsers are available in the FHS environment
  playwright-browsers ? null,
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
  inherit stdenv lib coreutils gawk getconf gnugrep gnused jq copyDesktopItems makeDesktopItem unzip libsecret;
  inherit buildPackages at-spi2-atk autoPatchelfHook buildFHSEnv;
  inherit alsa-lib libgbm nss nspr libxrandr libxfixes libxext libxdamage libxcomposite;
  inherit libx11 libxkbfile libxcb systemdLibs fontconfig imagemagick libdbusmenu;
  inherit glib wayland libglvnd openssl webkitgtk_4_1 ripgrep which asar bash;
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

  # When running inside an FHS environment, ensure browsers are available for Playwright
  # This coordinates with home-manager playwright settings (PLAYWRIGHT_BROWSERS_PATH)
  # by making playwright.browsers available in the FHS environment PATH
  customizeFHSEnv =
    args:
    buildFHSEnv (
      args
      // {
        # Add playwright.browsers to targetPkgs so browsers are available in FHS PATH
        # This ensures Playwright can find browsers even if PLAYWRIGHT_BROWSERS_PATH
        # isn't passed through the FHS environment
        targetPkgs = pkgs:
          (args.targetPkgs pkgs)
          ++ lib.optional (playwright-browsers != null) playwright-browsers;
        # Create /opt/google/chrome directory for symlink fallback
        extraBuildCommands = (args.extraBuildCommands or "") + ''
          mkdir -p "$out/opt/google/chrome"
        '';
        # Use tmpfs for /opt/google/chrome so symlinks work
        extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [ "--tmpfs /opt/google/chrome" ];
        # Wrapper script that tries to find browsers in PATH and symlink to Playwright's expected location
        # This works with both system browsers and playwright.browsers (if added to targetPkgs)
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
