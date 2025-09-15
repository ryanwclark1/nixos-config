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
  programs.claude-code = {
    # ── Core toggle & package ───────────────────────────────────────────────────
    enable  = true;
    package = pkgs.claude-code;  # Change if you use an overlay/unstable attr

 # Load MCP servers from a JSON file next to this module (adjust path as needed)
    mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);

    # Point optional asset dirs to the official ~/.claude layout
    agentsDir   = "${claudeHome}/agents";
    commandsDir = "${claudeHome}/commands";
    hooksDir    = "${claudeHome}/hooks";

    # settings.json — keys match Claude Code docs
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
        PreToolUse = { Bash = "echo 'Running tool…' >&2"; };
        PostToolUse = { Bash = "echo 'Tool done.' >&2"; };
      };

      outputStyle = "Explanatory";
      model = "claude-4-sonnet";
      statusLine = { type = "command"; command = "${claudeHome}/statusline.sh"; };
      forceLoginMethod = "console";


      # Enable / filter project .mcp.json servers
      enableAllProjectMcpServers = true;
      enabledMcpjsonServers = [ ];
      disabledMcpjsonServers = [ ];

      # Example secret placeholders to be swapped in activation step
      apiKeyHelper = "${claudeHome}/bin/generate_api_key.sh";
      # Custom “integrations” block—just JSON that your workflows expect
      integrations = {
        context7 = { token = "{{SOPS:context7-token}}"; };
        github   = { pat   = "{{SOPS:github-pat}}"; };
        sourcebot = { apiKey = "{{SOPS:sourcebot/api-key}}"; };
      };

      # Example memory settings (user-level)
      memory = {
        enabled = true;
        dir = "{{HOME}}/.local/share/claude-code/memory";
        scope = "per-project";
        maxItems = 200;
      };
    };

    # You can still define inline agents/commands if you want:
    agents = {
      reviewer = {
        description  = "Minimal-diff code reviewer";
        model        = "claude-3-7-sonnet";
        systemPrompt = "Prefer minimal actionable diffs; prioritize correctness/security.";
        tools        = [ "git" "filesystem" ];
      };
    };

    commands = {
      "fix-ruff" = {
        description = "Auto-fix imports & format via Ruff";
        run         = "uv run ruff check --select I --fix . && uv run ruff format .";
      };
    };
  };

  # Ensure ~/.claude exists and seed a couple of helper files (optional)
  home.file."${claudeHome}/.keep".text = "";
  home.file."${claudeHome}/statusline.sh".text = ''
    #!/usr/bin/env bash
    printf " %s" "$(basename "$PWD")"
  '';

  home.file."${claudeHome}/statusline.sh".executable = true;

  # Post-write activation hook: replace SOPS placeholders and {{HOME}} in ~/.claude/settings.json
  home.activation.processClaudeSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu

    settings="${settingsPath}"
    if [ -f "$settings" ]; then
      echo "Processing SOPS secrets in Claude Code settings…"

      tmp=$(${pkgs.coreutils}/bin/mktemp)
      content="$(${pkgs.coreutils}/bin/cat "$settings")"

      # Replace SOPS placeholders with real secrets
      content=$(echo "$content" | ${pkgs.gnused}/bin/sed "s|{{SOPS:context7-token}}|$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})|g")
      content=$(echo "$content" | ${pkgs.gnused}/bin/sed "s|{{SOPS:github-pat}}|$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})|g")
      content=$(echo "$content" | ${pkgs.gnused}/bin/sed "s|{{SOPS:sourcebot/api-key}}|$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})|g")

      # Expand {{HOME}}
      content=$(echo "$content" | ${pkgs.gnused}/bin/sed "s|{{HOME}}|$HOME|g")

      echo "$content" > "$tmp"

      if ${pkgs.jq}/bin/jq . "$tmp" >/dev/null 2>&1; then
        ${pkgs.coreutils}/bin/mv "$tmp" "$settings"
        echo "Claude Code settings updated with SOPS secrets."
      else
        echo "Error: Invalid JSON after substitution; keeping original file."
        ${pkgs.coreutils}/bin/rm -f "$tmp"
      fi
    fi
  '';
}
