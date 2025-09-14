{
  pkgs,
  lib,
  ...
}:

{
  # Gemini CLI Package Configuration - GitHub Override
  #
  # STATUS: Building v0.4.1 from GitHub using nixpkgs patches
  #
  # Uses the same patch approach as nixpkgs to handle @lvce-editor/ripgrep
  # dependency that tries to download binaries during build

  home.packages = with pkgs; [
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

      # Custom install phase to handle workspace structure
      installPhase = ''
        runHook preInstall
        
        mkdir -p $out/lib/node_modules/@google/gemini-cli
        
        # Copy the entire source to preserve workspace structure
        cp -r . $out/lib/node_modules/@google/gemini-cli/
        
        # Create the main binary
        mkdir -p $out/bin
        cat > $out/bin/gemini << 'EOF'
        #!/usr/bin/env bash
        exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js "$@"
        EOF
        chmod +x $out/bin/gemini
        
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
}
