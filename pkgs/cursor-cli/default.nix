{
  lib,
  fetchurl,
  stdenv,
  autoPatchelfHook,
}:

let
  inherit (stdenv) hostPlatform;
  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/lab/2026.03.11-6dfa30c/linux/x64/agent-cli-package.tar.gz";
      hash = "sha256-pstWHWv8lCWRGucRB9+KPe8XX4c99VComNDbPzCLxn8=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/lab/2026.03.11-6dfa30c/linux/arm64/agent-cli-package.tar.gz";
      hash = "sha256-EnDPfMcvRDNvtBzO3HIwaPJ7T7GlNQOdOWkrxrpWKoY=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/lab/2026.03.11-6dfa30c/darwin/x64/agent-cli-package.tar.gz";
      hash = "sha256-6duYFdg4P6Y8ic3rnP6+3xBjMJpqW7eurFcC0QopChU=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/lab/2026.03.11-6dfa30c/darwin/arm64/agent-cli-package.tar.gz";
      hash = "sha256-CQqdvBPZkJkfVGzt5KaD1dogzKyeIN00A0jk90WHUY8=";
    };
  };
in
stdenv.mkDerivation {
  pname = "cursor-cli";
  version = "0-unstable-2026-03-11";

  src = sources.${hostPlatform.system};

  nativeBuildInputs = lib.optionals hostPlatform.isLinux [
    autoPatchelfHook
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/cursor-agent
    cp -r * $out/share/cursor-agent/
    ln -s $out/share/cursor-agent/cursor-agent $out/bin/cursor-agent

    runHook postInstall
  '';

  passthru = {
    inherit sources;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Cursor CLI";
    homepage = "https://cursor.com/cli";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [
      sudosubin
      andrewbastin
    ];
    platforms = builtins.attrNames sources;
    mainProgram = "cursor-agent";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}


