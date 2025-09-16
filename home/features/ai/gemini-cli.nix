{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Official user-level settings & dirs (per docs)
  geminiHome = "${config.home.homeDirectory}/.gemini";
  settingsPath = "${geminiHome}/settings.json";
in
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


    # JSON configuration settings
    settings = {
      theme = "Default";
      selectedAuthType = "oauth-personal";
      autoAccept = true;
      vimMode = true;
      ideMode = true;
      hasSeenIdeIntegrationNudge = true;
      # Import MCP servers configuration
      mcpServers = (builtins.fromJSON (builtins.readFile ./mcp-servers.json));
    };

    # Custom commands (if needed)
    # commands = {
    #   # Example: "mycommand" = "echo 'custom command'";
    # };
  };

  # Create .env file with secrets from SOPS
  home.file."${geminiHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
    onChange = ''
      # Expand SOPS secrets in .env file
      if [ -f "${geminiHome}/.env" ]; then
        tmp=$(${pkgs.coreutils}/bin/mktemp)
        while IFS= read -r line; do
          if [[ "$line" =~ ^([A-Z_]+)=\$\((.+)\)$ ]]; then
            var_name="''${BASH_REMATCH[1]}"
            cmd="''${BASH_REMATCH[2]}"
            value=$(eval "$cmd" 2>/dev/null || echo "")
            echo "$var_name=$value" >> "$tmp"
          else
            echo "$line" >> "$tmp"
          fi
        done < "${geminiHome}/.env"
        ${pkgs.coreutils}/bin/mv "$tmp" "${geminiHome}/.env"
      fi
    '';
  };
}
