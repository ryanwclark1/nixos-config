# Gemini CLI version override file
# This file is automatically updated by the gemini-cli-update.sh script
# Use: gemini-cli-version check 0.6.1

{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.6.1";

  src = pkgs.fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "v${version}";
    hash = "sha256-1QeVFPl6IH1iQFxrDZ0U8eTeLd+fIgSw1CkAiSGaL/s=";
  };

  # No patches needed for v0.6.1 - ripgrep dependency handling was fixed upstream
  # patches = [];

  npmDepsHash = "sha256-l5AFQH5h6CPNnuSP0jjla3UbBhjPDVEc8fL5NWcT1XQ=";

  nativeBuildInputs = with pkgs; [
    pkg-config
    python3
  ];

  buildInputs = with pkgs; [
    libsecret
    ripgrep
  ];

  preConfigure = ''
    mkdir -p packages/generated
    echo "export const GIT_COMMIT_INFO = { commitHash: '${src.rev}' };" > packages/generated/git-commit.ts
  '';

  # Use nixpkgs-style install phase for proper workspace handling
  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/gemini-cli}

    cp -r node_modules $out/share/gemini-cli/

    # Remove workspace symlinks that would be broken
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-test-utils
    rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion

    # Copy actual packages to replace broken symlinks
    cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
    cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    cp -r packages/a2a-server $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server

    # Create main binary symlink
    ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
    chmod +x "$out/bin/gemini"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line interface for Google Gemini";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "gemini";
  };
}