{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Official user-level settings & dirs (per docs)
  codexHome = "${config.home.homeDirectory}/.codex";
  configDir = ./config;
in
{
  # Install codex package manually to avoid conflicts with manual config.toml management
  # The programs.codex module automatically generates config.toml, which conflicts with
  # our manual home.file entry below. We manage the config file manually for full control.
  home.packages = [ pkgs.codex ];

  # Write MCP servers configuration to Codex home directory
  # This ensures Codex can read the MCP servers configuration
  home.file."${codexHome}/mcp-servers.json" = {
    source = ./mcp-servers.json;
  };

  # Create config.toml with comprehensive settings
  # Codex uses TOML format for its main configuration file
  home.file."${codexHome}/config.toml" = {
    force = true;
    text = ''
      # Codex Configuration
      # See: https://github.com/openai/codex/blob/main/docs/config.md

      # Model selection
      # model = "gpt-5-codex"  # Default on macOS/Linux
      # model_provider = "openai"

      # Feature flags
      [features]
      streamable_shell = false          # Experimental: Use streamable exec tool
      web_search_request = true         # Allow model to request web searches
      view_image_tool = true            # Include view_image tool (default: true)
      apply_patch_freeform = false      # Beta: Include freeform apply_patch tool
      unified_exec = false              # Experimental: Use unified PTY-backed exec tool
      rmcp_client = false              # Experimental: OAuth support for streamable HTTP MCP servers
      experimental_sandbox_command_assessment = false  # Model-based sandbox risk assessment
      ghost_commit = false              # Experimental: Create ghost commit each turn
      enable_experimental_windows_sandbox = false  # Windows restricted-token sandbox

      # Execution environment
      [shell_environment_policy]
      inherit = "all"                   # Options: all, core, none
      # exclude = ["AWS_*", "AZURE_*"]  # Exclude patterns
      # include_only = ["PATH", "HOME", "USER"]  # Include only these
      # set = { CI = "1" }              # Force-set values

      # Sandbox configuration
      # approval_policy = "untrusted"    # Options: untrusted, on-failure, on-request, never
      # sandbox_mode = "workspace-write" # Options: read-only, workspace-write, danger-full-access

      # MCP Servers Configuration
      # MCP servers are configured via:
      # 1. programs.codex.settings.mcpServers (if supported by the NixOS module)
      # 2. ${codexHome}/mcp-servers.json (primary file-based configuration)
      # The source file is ./mcp-servers.json in the Nix configuration.
      # The TOML format for MCP servers is not the primary configuration method
      # and may not be fully supported by Codex.

      # MCP server timeouts (per-server configuration)
      # Example timeout configuration (if supported):
      # [mcp_servers.context7]
      # startup_timeout_sec = 10
      # tool_timeout_sec = 60

      # Project documentation
      # project_doc_max_bytes = 100000  # Max bytes to read from AGENTS.md

      # History persistence
      # [history]
      # persistence = "save-all"        # Options: save-all, none
      # max_bytes = 1000000              # Currently ignored

      # TUI settings
      # [tui]
      # notifications = false           # Enable desktop notifications

      # Model reasoning (for supported models like o3, o4-mini, codex-*)
      # model_reasoning_effort = "medium"  # Options: minimal, low, medium, high
      # model_reasoning_summary = "auto"   # Options: auto, concise, detailed, none
      # model_verbosity = "medium"         # Options: low, medium, high (GPT-5 Responses API)

      # File opener for clickable citations
      # file_opener = "vscode"          # Options: vscode, vscode-insiders, windsurf, cursor, none
    '';
  };

  # Copy configuration documentation files (similar to Claude setup)
  home.file."${codexHome}/RULES.md" = {
    source = "${configDir}/RULES.md";
  };
  home.file."${codexHome}/PRINCIPLES.md" = {
    source = "${configDir}/PRINCIPLES.md";
  };
  home.file."${codexHome}/MCP_Context7.md" = {
    source = "${configDir}/MCP_Context7.md";
  };
  home.file."${codexHome}/MCP_Playwright.md" = {
    source = "${configDir}/MCP_Playwright.md";
  };
  home.file."${codexHome}/MCP_Sequential.md" = {
    source = "${configDir}/MCP_Sequential.md";
  };
  home.file."${codexHome}/MCP_Serena.md" = {
    source = "${configDir}/MCP_Serena.md";
  };

  # Create .env file with secrets from SOPS
  # This file is generated at runtime by the systemd service
  home.file."${codexHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      # This file is generated at runtime by the generate-codex-env service
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
        #!/usr/bin/env bash
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
        # Generated by systemd service: generate-codex-env
        CONTEXT7_TOKEN=$(cat "${config.sops.secrets.context7-token.path}")
        GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
        SOURCEBOT_API_KEY=$(cat "${config.sops.secrets."sourcebot/api-key".path}")
        EOF

        chmod 600 "${codexHome}/.env"
        echo "Generated Codex .env file with actual secret values"
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
