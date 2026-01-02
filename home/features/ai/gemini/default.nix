{
  config,
  pkgs,
  lib,
  ...
}:

let
  geminiHome = "${config.home.homeDirectory}/.gemini";
in
{
  # Install gemini-cli package
  # Temporarily disabled due to npm build cache issue
  # home.packages = [ pkgs.gemini-cli ];
  home.packages = [ ];

  home.file."${geminiHome}/AGENTS.md" = {
    force = true;
    source = ./config/AGENTS.md;
  };
  home.file."${geminiHome}/FLAGS.md" = {
    force = true;
    source = ./config/FLAGS.md;
  };
  home.file."${geminiHome}/PRINCIPLES.md" = {
    force = true;
    source = ./config/PRINCIPLES.md;
  };
  home.file."${geminiHome}/RULES.md" = {
    force = true;
    source = ./config/RULES.md;
  };

  # MODES
  home.file."${geminiHome}/MODE_Brainstorming.md" = {
    force = true;
    source = ./config/MODE_Brainstorming.md;
  };
  home.file."${geminiHome}/MODE_Introspection.md" = {
    force = true;
    source = ./config/MODE_Introspection.md;
  };
  home.file."${geminiHome}/MODE_Orchestration.md" = {
    force = true;
    source = ./config/MODE_Orchestration.md;
  };
  home.file."${geminiHome}/MODE_Task_Management.md" = {
    force = true;
    source = ./config/MODE_Task_Management.md;
  };
  home.file."${geminiHome}/MODE_Token_Efficiency.md" = {
    force = true;
    source = ./config/MODE_Token_Efficiency.md;
  };

  # MCP SERVERS
  home.file."${geminiHome}/MCP_Context7.md" = {
    force = true;
    source = ./config/MCP_Context7.md;
  };
  home.file."${geminiHome}/MCP_Playwright.md" = {
    force = true;
    source = ./config/MCP_Playwright.md;
  };
  home.file."${geminiHome}/MCP_Sequential.md" = {
    force = true;
    source = ./config/MCP_Sequential.md;
  };
  home.file."${geminiHome}/MCP_Serena.md" = {
    force = true;
    source = ./config/MCP_Serena.md;
  };

  # AGENTS
  home.file."${geminiHome}/agents/backend-architect.md" = {
    force = true;
    source = ./config/agents/backend-architect.md;
  };
  home.file."${geminiHome}/agents/devops-architect.md" = {
    force = true;
    source = ./config/agents/devops-architect.md;
  };
  home.file."${geminiHome}/agents/frontend-architect.md" = {
    force = true;
    source = ./config/agents/frontend-architect.md;
  };
  home.file."${geminiHome}/agents/learning-guide.md" = {
    force = true;
    source = ./config/agents/learning-guide.md;
  };
  home.file."${geminiHome}/agents/performance-engineer.md" = {
    force = true;
    source = ./config/agents/performance-engineer.md;
  };
  home.file."${geminiHome}/agents/python-expert.md" = {
    force = true;
    source = ./config/agents/python-expert.md;
  };
  home.file."${geminiHome}/agents/quality-engineer.md" = {
    force = true;
    source = ./config/agents/quality-engineer.md;
  };
  home.file."${geminiHome}/agents/refactoring-expert.md" = {
    force = true;
    source = ./config/agents/refactoring-expert.md;
  };
  home.file."${geminiHome}/agents/requirements-analyst.md" = {
    force = true;
    source = ./config/agents/requirements-analyst.md;
  };
  home.file."${geminiHome}/agents/root-cause-analyst.md" = {
    force = true;
    source = ./config/agents/root-cause-analyst.md;
  };
  home.file."${geminiHome}/agents/security-engineer.md" = {
    force = true;
    source = ./config/agents/security-engineer.md;
  };
  home.file."${geminiHome}/agents/system-architect.md" = {
    force = true;
    source = ./config/agents/system-architect.md;
  };
  home.file."${geminiHome}/agents/technical-writer.md" = {
    force = true;
    source = ./config/agents/technical-writer.md;
  };

  # COMMANDS
  home.file."${geminiHome}/commands/sg/analyze.toml" = {
    force = true;
    source = ./config/commands/sg/analyze.toml;
  };
  home.file."${geminiHome}/commands/sg/build.toml" = {
    force = true;
    source = ./config/commands/sg/build.toml;
  };
  home.file."${geminiHome}/commands/sg/cleanup.toml" = {
    force = true;
    source = ./config/commands/sg/cleanup.toml;
  };
  home.file."${geminiHome}/commands/sg/design.toml" = {
    force = true;
    source = ./config/commands/sg/design.toml;
  };
  home.file."${geminiHome}/commands/sg/document.toml" = {
    force = true;
    source = ./config/commands/sg/document.toml;
  };
  home.file."${geminiHome}/commands/sg/estimate.toml" = {
    force = true;
    source = ./config/commands/sg/estimate.toml;
  };
  home.file."${geminiHome}/commands/sg/explain.toml" = {
    force = true;
    source = ./config/commands/sg/explain.toml;
  };
  home.file."${geminiHome}/commands/sg/git.toml" = {
    force = true;
    source = ./config/commands/sg/git.toml;
  };
  home.file."${geminiHome}/commands/sg/implement.toml" = {
    force = true;
    source = ./config/commands/sg/implement.toml;
  };
  home.file."${geminiHome}/commands/sg/improve.toml" = {
    force = true;
    source = ./config/commands/sg/improve.toml;
  };
  home.file."${geminiHome}/commands/sg/index.toml" = {
    force = true;
    source = ./config/commands/sg/index.toml;
  };
  home.file."${geminiHome}/commands/sg/load.toml" = {
    force = true;
    source = ./config/commands/sg/load.toml;
  };
  home.file."${geminiHome}/commands/sg/reflect.toml" = {
    force = true;
    source = ./config/commands/sg/reflect.toml;
  };
  home.file."${geminiHome}/commands/sg/save.toml" = {
    force = true;
    source = ./config/commands/sg/save.toml;
  };
  home.file."${geminiHome}/commands/sg/select-tool.toml" = {
    force = true;
    source = ./config/commands/sg/select-tool.toml;
  };
  home.file."${geminiHome}/commands/sg/test.toml" = {
    force = true;
    source = ./config/commands/sg/test.toml;
  };
  home.file."${geminiHome}/commands/sg/troubleshoot.toml" = {
    force = true;
    source = ./config/commands/sg/troubleshoot.toml;
  };


  # Manually manage settings.json to avoid backup conflicts
  # Using home.file instead of programs.gemini-cli to have full control
  home.file."${geminiHome}/settings.json" = {
    force = true;
    text = builtins.toJSON {
      autoAccept = true;
      hasSeenIdeIntegrationNudge = true;
      ideMode = true;
      selectedAuthType = "oauth-personal";
      theme = "Default";
      vimMode = true;

      # Import MCP servers configuration
      mcpServers = (builtins.fromJSON (builtins.readFile ./mcp-servers.json));
    };
  };

  # Create .env file with secrets from SOPS
  # Create a script that generates the .env file at runtime
  home.file."${geminiHome}/.env" = {
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
  systemd.user.services.generate-gemini-env = {
    Unit = {
      Description = "Generate Gemini .env file with SOPS secrets";
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "generate-gemini-env" ''
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
        cat > "${geminiHome}/.env" << EOF
        # MCP Server Environment Variables
        CONTEXT7_TOKEN=$(cat "${config.sops.secrets.context7-token.path}")
        GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
        SOURCEBOT_API_KEY=$(cat "${config.sops.secrets."sourcebot/api-key".path}")
        EOF

        chmod 600 "${geminiHome}/.env"
        echo "Generated .env file with actual secret values"
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
