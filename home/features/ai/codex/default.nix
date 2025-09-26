{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Official user-level settings & dirs (per docs)
  codexHome = "${config.home.homeDirectory}/.codex";
  settingsPath = "${codexHome}/settings.json";
in
{
  programs.codex = {
    enable  = true;

    package = pkgs.codex;
    settings = {
      model = "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL";
      model_provider = "ollama";
      model_providers = {
        ollama = {
          name = "Ollama";
          baseURL = "http://localhost:11434/v1";
          envKey = "";
        };
      };

      mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);
    };

    # custom-instructions = {
    #   # Example custom instruction
    #   "Always use markdown for code snippets" = "Whenever you provide code, format it using markdown code blocks with the appropriate language specified. This ensures proper syntax highlighting and readability.";
    # };
  };


  # Create .env file with secrets from SOPS
  # Create a script that generates the .env file at runtime
  home.file."${codexHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      # This file is generated at runtime by the .env-generator script
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
  };

  # Create a systemd user service to generate .env file after SOPS secrets are available
  systemd.user.services.generate-codex-env = {
    Unit = {
      Description = "Generate Codex .env file with SOPS secrets";
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "generate-codex-env" ''
        #!/bin/bash
        # Generate .env file with actual secret values at runtime

        # Check if secrets exist
        if [ ! -f "${config.sops.secrets.context7-token.path}" ] || \
           [ ! -f "${config.sops.secrets.github-pat.path}" ] || \
           [ ! -f "${config.sops.secrets."sourcebot/api-key".path}" ]; then
          echo "Warning: Some SOPS secrets are not available yet" >&2
          exit 1
        fi

        # Generate the .env file with actual values
        cat > "${codexHome}/.env" << EOF
        # MCP Server Environment Variables
        CONTEXT7_TOKEN=$(cat "${config.sops.secrets.context7-token.path}")
        GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
        SOURCEBOT_API_KEY=$(cat "${config.sops.secrets."sourcebot/api-key".path}")
        EOF

        chmod 600 "${codexHome}/.env"
        echo "Generated .env file with actual secret values"
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
