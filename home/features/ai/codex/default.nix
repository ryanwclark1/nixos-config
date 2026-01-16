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
      # See: https://developers.openai.com/codex/config-reference

      # Model selection
      # model = "gpt-5-codex"  # Default on macOS/Linux
      # model_provider = "openai"

      # Default profile (CLI only, not supported in IDE extension)
      profile = "development"

      # Project documentation
      project_doc_max_bytes = 200000  # Max bytes to read from AGENTS.md (200KB)
      project_root_markers = [".git", ".codex"]  # Project root detection markers

      # Model reasoning (for supported models like o3, o4-mini, codex-*)
      model_reasoning_effort = "medium"  # Options: minimal, low, medium, high, xhigh
      model_reasoning_summary = "auto"   # Options: auto, concise, detailed, none
      model_verbosity = "medium"         # Options: low, medium, high (GPT-5 Responses API)

      # Feature flags
      [features]
      streamable_shell = false          # Experimental: Use streamable exec tool
      web_search_request = true         # Stable: Allow model to request web searches
      view_image_tool = true            # Stable: Include view_image tool (default: true)
      shell_tool = true                 # Stable: Enable default shell tool (on by default)
      exec_policy = true                # Experimental: Enforce rules checks (on by default)
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
      approval_policy = "on-request"    # Options: untrusted, on-failure, on-request, never
      sandbox_mode = "workspace-write"   # Options: read-only, workspace-write, danger-full-access

      [sandbox_workspace_write]
      exclude_tmpdir_env_var = false    # Allow $TMPDIR
      exclude_slash_tmp = false         # Allow /tmp
      network_access = false             # Opt in to outbound network (disabled by default)
      # writable_roots = []              # Additional writable roots

      # MCP Servers Configuration
      # MCP servers are configured via:
      # 1. ${codexHome}/mcp-servers.json (primary file-based configuration)
      # 2. config.toml [mcp_servers.*] sections (for timeouts and overrides)

      # MCP server timeouts (per-server configuration)
      [mcp_servers.context7]
      startup_timeout_sec = 10
      tool_timeout_sec = 60

      [mcp_servers.sequential-thinking]
      startup_timeout_sec = 15
      tool_timeout_sec = 120  # Complex reasoning takes longer

      [mcp_servers.playwright]
      startup_timeout_sec = 10
      tool_timeout_sec = 90  # Browser operations can be slow

      [mcp_servers.github]
      startup_timeout_sec = 10
      tool_timeout_sec = 60

      [mcp_servers.serena]
      startup_timeout_sec = 10
      tool_timeout_sec = 60

      # History persistence
      [history]
      persistence = "save-all"          # Options: save-all, none
      # max_bytes = 1000000              # Currently ignored

      # TUI settings
      [tui]
      notifications = true               # Enable desktop notifications

      # File opener for clickable citations
      file_opener = "cursor"             # Options: vscode, vscode-insiders, windsurf, cursor, none

      # Configuration Profiles (CLI only)
      # Profiles allow switching between different configuration sets
      [profiles.deep-review]
      model = "gpt-5-codex"
      model_reasoning_effort = "high"
      approval_policy = "never"
      sandbox_mode = "workspace-write"

      [profiles.lightweight]
      model = "gpt-4.1"
      approval_policy = "untrusted"
      sandbox_mode = "read-only"
      model_reasoning_effort = "minimal"

      [profiles.development]
      model = "gpt-5-codex"
      model_reasoning_effort = "medium"
      approval_policy = "on-request"
      sandbox_mode = "workspace-write"
    '';
  };

  # Copy configuration documentation files (similar to Claude setup)
  home.file."${codexHome}/AGENTS.md" = {
    source = "${configDir}/AGENTS.md";
  };
  home.file."${codexHome}/PLANNING.md" = {
    source = "${configDir}/PLANNING.md";
  };
  home.file."${codexHome}/RULES.md" = {
    source = "${configDir}/RULES.md";
  };
  home.file."${codexHome}/PRINCIPLES.md" = {
    source = "${configDir}/PRINCIPLES.md";
  };
  home.file."${codexHome}/SKILLS.md" = {
    source = "${configDir}/SKILLS.md";
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
  home.file."${codexHome}/MCP_GitHub.md" = {
    source = "${configDir}/MCP_GitHub.md";
  };

  # Deploy Rules system
  home.file."${codexHome}/rules/default.rules" = {
    source = "${configDir}/rules/default.rules";
  };

  # Deploy Custom Prompts
  home.file."${codexHome}/prompts/draftpr.md" = {
    source = "${configDir}/prompts/draftpr.md";
  };
  home.file."${codexHome}/prompts/review.md" = {
    source = "${configDir}/prompts/review.md";
  };
  home.file."${codexHome}/prompts/refactor.md" = {
    source = "${configDir}/prompts/refactor.md";
  };
  home.file."${codexHome}/prompts/debug.md" = {
    source = "${configDir}/prompts/debug.md";
  };
  home.file."${codexHome}/prompts/test.md" = {
    source = "${configDir}/prompts/test.md";
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
