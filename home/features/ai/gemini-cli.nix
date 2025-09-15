{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.gemini-cli = {
    enable = true;

    package = pkgs.buildNpmPackage rec {
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
      };

    # Default model configuration
    # defaultModel = "gemini-1.5-flash";

    # JSON configuration settings
    settings = {
      theme = "Default";
      selectedAuthType = "oauth-personal";
      autoAccept = true;
      vimMode = true;
      ideMode = true;
      hasSeenIdeIntegrationNudge = true;
      # Import MCP servers configuration (will be processed by activation script)
      mcpServers = (builtins.fromJSON (builtins.readFile ./mcp-servers.json));
    };

    # Custom commands (if needed)
    commands = {
      # Example: "mycommand" = "echo 'custom command'";
    };
  };

  # Process SOPS secrets in the generated settings file
  home.activation.processGeminiMcpSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    gemini_settings="$HOME/.gemini/settings.json"
    
    if [ -f "$gemini_settings" ]; then
      echo "Processing SOPS secrets in Gemini CLI settings..."
      
      # Create a temporary file
      tmp_file=$(mktemp)
      
      # Read and process the settings file
      settings_content=$(cat "$gemini_settings")
      
      # Replace SOPS placeholders with actual secret values
      settings_content=$(echo "$settings_content" | sed "s|{{SOPS:context7-token}}|$(cat ${config.sops.secrets.context7-token.path})|g")
      settings_content=$(echo "$settings_content" | sed "s|{{SOPS:github-pat}}|$(cat ${config.sops.secrets.github-pat.path})|g")
      settings_content=$(echo "$settings_content" | sed "s|{{SOPS:sourcebot/api-key}}|$(cat ${config.sops.secrets."sourcebot/api-key".path})|g")
      settings_content=$(echo "$settings_content" | sed "s|{{HOME}}|$HOME|g")
      
      # Write the processed content back
      echo "$settings_content" > "$tmp_file"
      
      # Validate JSON and replace if valid
      if ${pkgs.jq}/bin/jq . "$tmp_file" >/dev/null 2>&1; then
        mv "$tmp_file" "$gemini_settings"
        echo "SOPS secrets processed successfully in Gemini CLI settings"
      else
        echo "Error: Invalid JSON generated, keeping original settings"
        rm -f "$tmp_file"
      fi
    fi
  '';
}
