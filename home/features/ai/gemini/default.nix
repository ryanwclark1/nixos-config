{
  config,
  pkgs,
  lib,
  ...
}:

let
  geminiHome = "${config.home.homeDirectory}/.gemini";
  settingsPath = "${geminiHome}/settings.json";
in
{
  home.file."${geminiHome}/AGENTS.md" = {
    source = ./config/AGENTS.md;
  };
  home.file."${geminiHome}/FLAGS.md" = {
    source = ./config/FLAGS.md;
  };
  home.file."${geminiHome}/PRINCIPLES.md" = {
    source = ./config/PRINCIPLES.md;
  };
  home.file."${geminiHome}/RULES.md" = {
    source = ./config/RULES.md;
  };

  # MODES
  home.file."${geminiHome}/MODE_Brainstorming.md" = {
    source = ./config/MODE_Brainstorming.md;
  };
  home.file."${geminiHome}/MODE_Introspection.md" = {
    source = ./config/MODE_Introspection.md;
  };
  home.file."${geminiHome}/MODE_Orchestration.md" = {
    source = ./config/MODE_Orchestration.md;
  };
  home.file."${geminiHome}/MODE_Task_Management.md" = {
    source = ./config/MODE_Task_Management.md;
  };
  home.file."${geminiHome}/MODE_Token_Efficiency.md" = {
    source = ./config/MODE_Token_Efficiency.md;
  };

  # MCP SERVERS
  home.file."${geminiHome}/MCP_Context7.md" = {
    source = ./config/MCP_Context7.md;
  };
  home.file."${geminiHome}/MCP_Playwright.md" = {
    source = ./config/MCP_Playwright.md;
  };
  home.file."${geminiHome}/MCP_Sequential.md" = {
    source = ./config/MCP_Sequential.md;
  };
  home.file."${geminiHome}/MCP_Serena.md" = {
    source = ./config/MCP_Serena.md;
  };

  # AGENTS
  home.file."${geminiHome}/agents/backend-architect.md" = {
    source = ./config/agents/backend-architect.md;
  };
  home.file."${geminiHome}/agents/devops-architect.md" = {
    source = ./config/agents/devops-architect.md;
  };
  home.file."${geminiHome}/agents/frontend-architect.md" = {
    source = ./config/agents/frontend-architect.md;
  };
  home.file."${geminiHome}/agents/learning-guide.md" = {
    source = ./config/agents/learning-guide.md;
  };
  home.file."${geminiHome}/agents/performance-engineer.md" = {
    source = ./config/agents/performance-engineer.md;
  };
  home.file."${geminiHome}/agents/python-expert.md" = {
    source = ./config/agents/python-expert.md;
  };
  home.file."${geminiHome}/agents/quality-engineer.md" = {
    source = ./config/agents/quality-engineer.md;
  };
  home.file."${geminiHome}/agents/refactoring-expert.md" = {
    source = ./config/agents/refactoring-expert.md;
  };
  home.file."${geminiHome}/agents/requirements-analyst.md" = {
    source = ./config/agents/requirements-analyst.md;
  };
  home.file."${geminiHome}/agents/root-cause-analyst.md" = {
    source = ./config/agents/root-cause-analyst.md;
  };
  home.file."${geminiHome}/agents/security-engineer.md" = {
    source = ./config/agents/security-engineer.md;
  };
  home.file."${geminiHome}/agents/system-architect.md" = {
    source = ./config/agents/system-architect.md;
  };
  home.file."${geminiHome}/agents/technical-writer.md" = {
    source = ./config/agents/technical-writer.md;
  };

  # COMMANDS
  home.file."${geminiHome}/commands/sg/analyze.toml" = {
    source = ./config/commands/sg/analyze.toml;
  };
  home.file."${geminiHome}/commands/sg/build.toml" = {
    source = ./config/commands/sg/build.toml;
  };
  home.file."${geminiHome}/commands/sg/cleanup.toml" = {
    source = ./config/commands/sg/cleanup.toml;
  };
  home.file."${geminiHome}/commands/sg/design.toml" = {
    source = ./config/commands/sg/design.toml;
  };
  home.file."${geminiHome}/commands/sg/document.toml" = {
    source = ./config/commands/sg/document.toml;
  };
  home.file."${geminiHome}/commands/sg/estimate.toml" = {
    source = ./config/commands/sg/estimate.toml;
  };
  home.file."${geminiHome}/commands/sg/explain.toml" = {
    source = ./config/commands/sg/explain.toml;
  };
  home.file."${geminiHome}/commands/sg/git.toml" = {
    source = ./config/commands/sg/git.toml;
  };
  home.file."${geminiHome}/commands/sg/implement.toml" = {
    source = ./config/commands/sg/implement.toml;
  };
  home.file."${geminiHome}/commands/sg/improve.toml" = {
    source = ./config/commands/sg/improve.toml;
  };
  home.file."${geminiHome}/commands/sg/index.toml" = {
    source = ./config/commands/sg/index.toml;
  };
  home.file."${geminiHome}/commands/sg/load.toml" = {
    source = ./config/commands/sg/load.toml;
  };
  home.file."${geminiHome}/commands/sg/reflect.toml" = {
    source = ./config/commands/sg/reflect.toml;
  };
  home.file."${geminiHome}/commands/sg/save.toml" = {
    source = ./config/commands/sg/save.toml;
  };
  home.file."${geminiHome}/commands/sg/select-tool.toml" = {
    source = ./config/commands/sg/select-tool.toml;
  };
  home.file."${geminiHome}/commands/sg/test.toml" = {
    source = ./config/commands/sg/test.toml;
  };
  home.file."${geminiHome}/commands/sg/troubleshoot.toml" = {
    source = ./config/commands/sg/troubleshoot.toml;
  };


  programs.gemini-cli = {
    enable = true;
    package = pkgs.gemini-cli;
    settings = {
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
