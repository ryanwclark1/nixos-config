{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  appimageTools,
  undmg,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:

let
  inherit (stdenv) hostPlatform;
  finalCommandLineArgs = "--update=false " + commandLineArgs;

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/linux/x64/Cursor-2.2.20-x86_64.AppImage";
      hash = "sha256-dY42LaaP7CRbqY2tuulJOENa+QUGSL09m07PvxsZCr0=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/linux/arm64/Cursor-2.2.20-aarch64.AppImage";
      hash = "sha256-7z5z8v7UWj3hUWv9q7SvXlRUb859JhLTP73MIyjKS30=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-6nb6Q5h9LK0zblD0acg+PO3NPqpe6vstgKllIuhWfTw=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-7EApheXkyDrEDCCF66uh0v1dkk3Ha6RnWR7K0OVI7M4=";
    };
  };

  source = sources.${hostPlatform.system};
in
(callPackage ../vscode-generic/generic.nix rec {
  inherit useVSCodeRipgrep;
  commandLineArgs = finalCommandLineArgs;

  version = "2.2.20";
  pname = "cursor";

  # You can find the current VSCode version in the About dialog:
  # workbench.action.showAboutDialog (Help: About)
  # Note: Update this when Cursor updates its underlying VSCode version
  vscodeVersion = "1.105.1";

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

  # Editing the `cursor` binary within the app bundle causes the bundle's signature
  # to be invalidated, which prevents launching starting with macOS Ventura, because Cursor is notarized.
  # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
  dontFixup = stdenv.hostPlatform.isDarwin;

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
      updateScript = ./update.sh;
    };
  })
