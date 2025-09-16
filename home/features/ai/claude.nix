{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Official user-level settings & dirs (per docs)
  claudeHome = "${config.home.homeDirectory}/.claude";
  settingsPath = "${claudeHome}/settings.json";
in
{
  home.file.".claude/statusline.sh" = {
    source = ./statusline.sh;
    executable = true;
  };

  programs.claude-code = {
    enable  = true;

    package = pkgs.claude-code;  # Change if you use an overlay/unstable attr

    settings = {
      # Example: global env vars applied to sessions
      env = {
        # Toggle telemetry etc. via env (can also be set externally)
        DISABLE_TELEMETRY = "1";
        USE_BUILTIN_RIPGREP = "0"; # prefer system rg

      };

      # Permissions (deny sensitive files; allow/ask examples)
      permissions = {
        allow = [
          "Bash(npm run lint)"
          "Bash(npm run test:*)"
          "Read(~/.zshrc)"
        ];
        ask = [
          "Bash(git push:*)"
        ];
        additionalDirectories = [ "../docs/" ];
        defaultMode = "acceptEdits";
        disableBypassPermissionsMode = "disable";
      };

      # Hooks: run before/after tool use (example)
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              { type = "command"; command = "echo 'Running tool…' >&2"; }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Bash";
            hooks = [
              { type = "command"; command = "echo 'Tool done.' >&2"; }
            ];
          }
        ];
      };

      outputStyle = "Explanatory";
      model = "sonnet";

      statusLine = {
        type = "command";
        command = "${claudeHome}/statusline.sh";
        padding = 0; # Optional: set to 0 to let status line go to
      };

      # statusLine = {
      #   type = "command";
      #   command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
      # };
      forceLoginMethod = "console";


      # Example memory settings (user-level)
      memory = {
        enabled = true;
        dir = "{{HOME}}/.local/share/claude-code/memory";
        scope = "per-project";
        maxItems = 200;
      };

      # Load MCP servers from a JSON file next to this module (adjust path as needed)
      # mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);
    };

    mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);

    # You can still define inline agents/commands if you want:
    agents = {
      reviewer = ''
        ---
        name: reviewer
        model: claude-sonnet
        system_prompt: Prefer minimal actionable diffs; prioritize correctness/security.
        tools: git, filesystem
        description: Minimal-diff code reviewer that focuses on providing actionable, security-focused code review feedback.
        ---

        # Minimal-diff code reviewer

        A code review agent that prioritizes minimal, actionable diffs with a focus on correctness and security.
      '';
    };

    commands = {
      "fix-ruff" = ''
        # Auto-fix imports & format via Ruff

        **Description**: Auto-fix imports & format via Ruff

        **Command**:
        ```bash
        uv run ruff check --select I --fix . && uv run ruff format .
        ```
      '';
    };
  };

  # Create .env file with secrets from SOPS
  home.file."${claudeHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
    onChange = ''
      # Expand SOPS secrets in .env file
      if [ -f "${claudeHome}/.env" ]; then
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
        done < "${claudeHome}/.env"
        ${pkgs.coreutils}/bin/mv "$tmp" "${claudeHome}/.env"
      fi
    '';
  };
}
