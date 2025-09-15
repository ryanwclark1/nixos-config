{
  pkgs,
  lib,
  ...
}:

{
  programs.gemini-cli = {
    enable = true;

    package = with pkgs; [
      (pkgs.buildNpmPackage rec {
        pname = "gemini-cli";
        version = "0.4.1";

        src = pkgs.fetchFromGitHub {
          owner = "google-gemini";
          repo = "gemini-cli";
          rev = "v${version}";
          hash = "sha256-SyYergPmEyIcDyU0tF20pvu1qOCRfMRozh0/9nnaefU=";
        };

        # Single combined patch for v0.4.1 to remove ripgrep dependency
        patches = [
          ./replace-npm-rg-with-local-v0.4.1.patch
        ];

        npmDepsHash = "sha256-4S1wMl1agTYOwJ8S/CsXHG+JRx40Nee23TmoJyTYoII="; # Need new hash after removing dependency

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
      })
    ];

    # Default model configuration
    # defaultModel = "gemini-1.5-flash";

    # JSON configuration settings
    settings = {
      # Add any specific configuration options here
    };

    # Custom commands (if needed)
    commands = {
      # Example: "mycommand" = "echo 'custom command'";
    };
  };
}
